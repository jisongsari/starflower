import type { GeoResult } from "../types";

// 위치 검색
// 1순위: Nominatim(OpenStreetMap) — 한글 부분검색에 강함 ("서울" → 서울특별시)
// 백업:  Open-Meteo 지오코딩 — Nominatim이 실패/결과없음일 때
//
// 의미 없는 한 글자 입력으로 엉뚱한 결과가 쏟아지지 않도록
// (1) 최소 2글자부터 검색하고 (2) 거주지/행정구역 유형만 남긴다.
export async function searchLocations(query: string): Promise<GeoResult[]> {
  const q = query.trim();
  if (q.length < 2) return []; // 한 글자 등 의미 없는 입력 차단

  try {
    const nm = await searchNominatim(q);
    if (nm.length > 0) return nm;
  } catch {
    /* 백업으로 */
  }
  try {
    return await searchOpenMeteo(q);
  } catch {
    return [];
  }
}

// 도시·마을·행정구역 등 "장소"로 인정할 유형만 통과
const PLACE_TYPES = new Set([
  "city",
  "town",
  "village",
  "hamlet",
  "municipality",
  "suburb",
  "neighbourhood",
  "quarter",
  "borough",
  "city_district",
  "district",
  "county",
  "province",
  "state",
  "region",
  "administrative",
  "island",
]);

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
  address?: {
    city?: string;
    town?: string;
    village?: string;
    county?: string;
    state?: string;
    province?: string;
    country?: string;
  };
}

async function searchNominatim(q: string): Promise<GeoResult[]> {
  const url = new URL("https://nominatim.openstreetmap.org/search");
  url.searchParams.set("q", q);
  url.searchParams.set("format", "jsonv2");
  url.searchParams.set("addressdetails", "1");
  url.searchParams.set("accept-language", "ko");
  url.searchParams.set("limit", "10");

  const res = await fetch(url.toString(), {
    headers: { "Accept-Language": "ko" },
  });
  if (!res.ok) throw new Error("nominatim failed");
  const data: NominatimItem[] = await res.json();

  const seen = new Set<string>();
  const out: GeoResult[] = [];

  for (const it of data) {
    // 거주지/행정구역 유형만 (도로·상점·건물 등 제외)
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

    // 중복 제거 (같은 이름+상위행정구역)
    const key = `${name}|${admin1 ?? ""}|${country ?? ""}`;
    if (seen.has(key)) continue;
    seen.add(key);

    out.push({ id: it.place_id, name, admin1, country, latitude: lat, longitude: lon });
    if (out.length >= 6) break;
  }
  return out;
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
