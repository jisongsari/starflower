// Open-Meteo: 날씨 예보 + 대기질 (둘 다 API 키 불필요)

export interface RawWeather {
  timezone: string;
  current: {
    time: string;
    temperature_2m: number;
    relative_humidity_2m: number;
    cloud_cover: number;
    wind_speed_10m: number;
    surface_pressure: number;
    weather_code: number;
    is_day: number;
  };
  hourly: {
    time: string[];
    cloud_cover: number[];
    relative_humidity_2m: number[];
    wind_speed_10m: number[];
    temperature_2m: number[];
    weather_code: number[];
  };
  daily: {
    time: string[];
    sunrise: string[];
    sunset: string[];
  };
}

export interface RawAir {
  hourly: {
    time: string[];
    pm2_5: number[];
  };
}

export async function fetchWeather(lat: number, lng: number): Promise<RawWeather> {
  const url = new URL("https://api.open-meteo.com/v1/forecast");
  url.searchParams.set("latitude", String(lat));
  url.searchParams.set("longitude", String(lng));
  url.searchParams.set(
    "current",
    "temperature_2m,relative_humidity_2m,cloud_cover,wind_speed_10m,surface_pressure,weather_code,is_day"
  );
  url.searchParams.set(
    "hourly",
    "cloud_cover,relative_humidity_2m,wind_speed_10m,temperature_2m,weather_code"
  );
  url.searchParams.set("daily", "sunrise,sunset");
  url.searchParams.set("wind_speed_unit", "ms");
  url.searchParams.set("timezone", "auto");
  url.searchParams.set("forecast_days", "4");

  const res = await fetch(url.toString());
  if (!res.ok) throw new Error("날씨 정보를 불러오지 못했어요.");
  return res.json();
}

export async function fetchAir(lat: number, lng: number): Promise<RawAir | null> {
  try {
    const url = new URL("https://air-quality-api.open-meteo.com/v1/air-quality");
    url.searchParams.set("latitude", String(lat));
    url.searchParams.set("longitude", String(lng));
    url.searchParams.set("hourly", "pm2_5");
    url.searchParams.set("timezone", "auto");
    url.searchParams.set("forecast_days", "4");
    const res = await fetch(url.toString());
    if (!res.ok) return null; // 대기질은 실패해도 진행 (페널티 0 처리)
    return res.json();
  } catch {
    return null;
  }
}
