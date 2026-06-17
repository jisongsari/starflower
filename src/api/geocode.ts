import type { GeoResult } from "../types";

// 한글 포함 여부
const isKorean = (s: string) => /[\uAC00-\uD7A3\u1100-\u11FF\u3130-\u318F]/.test(s);

// 도시·마을·행정구역으로 인정할 유형
const PLACE_TYPES = new Set([
  "city", "town", "village", "hamlet", "municipality",
  "suburb", "neighbourhood", "quarter", "borough",
  "city_district", "district", "county", "province",
  "state", "region", "administrative", "island",
]);

export async function searchLocations(query: string): Promise<GeoResult[]> {
  const q = query.trim();
  if (q.length < 2) return [];

  try {
    const results = await searchNominatim(q);
    if (results.length > 0) return results;
  } catch { /* 백업으로 */ }

  try {
    return await searchOpenMeteo(q);
  } catch {
    return [];
  }
}

// ── Nominatim ──────────────────────────────────────────────
interface NominatimItem {
  place_id: number;
  lat: string;
  lon: string;
  name?: string;
  display_name: string;
  addresstype?: string;
  type?: string;
  category?: string;
  importance?: number;
  address?: {
    city?: string;
    town?: string;
    village?: string;
    county?: string;
    state?: string;
    province?: string;
    country?: string;
    country_code?: string;
  };
}

function nominatimFetch(q: string, extraParams: Record<string, string> = {}): Promise<NominatimItem[]> {
  const url = new URL("https://nominatim.openstreetmap.org/search");
  url.searchParams.set("q", q);
  url.searchParams.set("format", "jsonv2");
  url.searchParams.set("addressdetails", "1");
  url.searchParams.set("accept-language", "ko");
  url.searchParams.set("limit", "10");
  for (const [k, v] of Object.entries(extraParams)) url.searchParams.set(k, v);
  return fetch(url.toString(), { headers: { "Accept-Language": "ko" } })
    .then((r) => (r.ok ? r.json() : Promise.reject()));
}

function parseItems(items: NominatimItem[]): GeoResult[] {
  const seen = new Set<string>();
  const out: GeoResult[] = [];

  // importance 내림차순 정렬 (큰 도시가 위로)
  const sorted = [...items].sort((a, b) => (b.importance ?? 0) - (a.importance ?? 0));

  for (const it of sorted) {
    const kind = it.addresstype || it.type || "";
    const isPlace =
      PLACE_TYPES.has(kind) || it.category === "place" || it.category === "boundary";
    if (!isPlace) continue;

    const lat = parseFloat(it.lat);
    const lon = parseFloat(it.lon);
    if (!Number.isFinite(lat) || !Number.isFinite(lon)) continue;

    const a = it.address ?? {};
    const name =
      it.name || a.city || a.town || a.village || it.display_name.split(",")[0].trim();
    const admin1 = a.state || a.province;
    const country = a.country;

    const key = `${name}|${admin1 ?? ""}|${country ?? ""}`;
    if (seen.has(key)) continue;
    seen.add(key);

    out.push({ id: it.place_id, name, admin1, country, latitude: lat, longitude: lon });
    if (out.length >= 6) break;
  }
  return out;
}

async function searchNominatim(q: string): Promise<GeoResult[]> {
  if (isKorean(q)) {
    // 한글: 한국 우선 + 전세계 병렬 요청 → 한국 결과를 앞에 배치
    const [krItems, allItems] = await Promise.allSettled([
      nominatimFetch(q, { countrycodes: "kr" }),
      nominatimFetch(q),
    ]);

    const kr = krItems.status === "fulfilled" ? krItems.value : [];
    const all = allItems.status === "fulfilled" ? allItems.value : [];

    // 한국 결과 먼저, 나머지는 importance 순으로
    const krIds = new Set(kr.map((i) => i.place_id));
    const rest = all.filter((i) => !krIds.has(i.place_id));
    const merged = [...kr, ...rest];

    return parseItems(merged);
  } else {
    // 로마자 등: 전세계 검색
    const items = await nominatimFetch(q);
    return parseItems(items);
  }
}

// ── Open-Meteo (백업) ──────────────────────────────────────
interface RawGeo {
  results?: Array<{
    id: number;
    name: string;
    latitude: number;
    longitude: number;
    country?: string;
    admin1?: string;
  }>;
}

async function searchOpenMeteo(q: string): Promise<GeoResult[]> {
  const url = new URL("https://geocoding-api.open-meteo.com/v1/search");
  url.searchParams.set("name", q);
  url.searchParams.set("count", "6");
  url.searchParams.set("language", "ko");
  url.searchParams.set("format", "json");

  const res = await fetch(url.toString());
  if (!res.ok) throw new Error("open-meteo geocoding failed");
  const data: RawGeo = await res.json();
  if (!data.results) return [];
  return data.results.map((r) => ({
    id: r.id,
    name: r.name,
    admin1: r.admin1,
    country: r.country,
    latitude: r.latitude,
    longitude: r.longitude,
  }));
}
