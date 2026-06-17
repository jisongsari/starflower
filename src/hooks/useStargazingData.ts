import { useCallback, useEffect, useState } from "react";
import type {
  DayForecast,
  SavedLocation,
  StargazingData,
} from "../types";
import { fetchWeather, fetchAir, type RawWeather, type RawAir } from "../api/openMeteo";
import { computeScore } from "../lib/score";
import { classifySky } from "../lib/theme";
import { getMoonState, getSunAltitude, moonExposureOverNight, moonPhaseName } from "../lib/moon";

const WEEKDAYS = ["일", "월", "화", "수", "목", "금", "토"];

function pad(n: number) {
  return n < 10 ? "0" + n : String(n);
}
function dateStr(d: Date) {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}
function addDays(d: Date, n: number) {
  const x = new Date(d);
  x.setDate(x.getDate() + n);
  return x;
}
function avg(nums: number[]): number {
  const valid = nums.filter((n) => Number.isFinite(n));
  if (valid.length === 0) return 0;
  return valid.reduce((a, b) => a + b, 0) / valid.length;
}

// 하나의 밤(저녁 19시 ~ 다음날 05시) 구간에 해당하는 hourly 인덱스 모으기
function nightIndices(times: string[], eveningDate: string, morningDate: string): number[] {
  const out: number[] = [];
  for (let i = 0; i < times.length; i++) {
    const [d, t] = times[i].split("T");
    const hour = parseInt(t.slice(0, 2), 10);
    if ((d === eveningDate && hour >= 19) || (d === morningDate && hour <= 5)) {
      out.push(i);
    }
  }
  return out;
}

// 밤 구간 한가운데(자정 무렵) 시각 Date 만들기
function nightMidnight(eveningDate: string): Date {
  const [y, m, d] = eveningDate.split("-").map(Number);
  const dt = new Date(y, m - 1, d, 24, 0, 0); // 다음날 00:00
  return dt;
}
function nightStart(eveningDate: string): Date {
  const [y, m, d] = eveningDate.split("-").map(Number);
  return new Date(y, m - 1, d, 19, 0, 0);
}
function nightEnd(eveningDate: string): Date {
  const [y, m, d] = eveningDate.split("-").map(Number);
  return new Date(y, m - 1, d + 1, 5, 0, 0);
}

function airAt(air: RawAir | null, times: string[], idxs: number[]): number {
  if (!air || !air.hourly?.pm2_5) return 0;
  // 날씨 hourly 인덱스를 시간 문자열로 대기질 배열에 매칭
  const vals: number[] = [];
  for (const i of idxs) {
    const t = times[i];
    const j = air.hourly.time.indexOf(t);
    if (j >= 0) vals.push(air.hourly.pm2_5[j]);
  }
  return avg(vals);
}

function buildData(
  location: SavedLocation,
  weather: RawWeather,
  air: RawAir | null
): StargazingData {
  const { latitude: lat, longitude: lng } = location;
  const now = new Date();
  const cur = weather.current;
  const hourly = weather.hourly;

  // 활성 밤: 새벽(06시 이전)이면 어젯밤이 진행 중, 아니면 오늘 저녁
  const todayEvening = now.getHours() < 6 ? addDays(now, -1) : now;

  const forecast: DayForecast[] = [];
  let night0: { cloud: number; humidity: number; wind: number; pm25: number } | null =
    null;
  for (let i = 0; i < 3; i++) {
    const evening = addDays(todayEvening, i);
    const eveningDate = dateStr(evening);
    const morningDate = dateStr(addDays(evening, 1));
    const idxs = nightIndices(hourly.time, eveningDate, morningDate);

    const cloud = avg(idxs.map((k) => hourly.cloud_cover[k]));
    const humidity = avg(idxs.map((k) => hourly.relative_humidity_2m[k]));
    const wind = avg(idxs.map((k) => hourly.wind_speed_10m[k]));
    const pm25 = airAt(air, hourly.time, idxs);

    if (i === 0) night0 = { cloud, humidity, wind, pm25 };

    const moonMid = getMoonState(nightMidnight(eveningDate), lat, lng);
    const exposure = moonExposureOverNight(
      nightStart(eveningDate),
      nightEnd(eveningDate),
      lat,
      lng
    );

    const result = computeScore({
      cloud,
      humidity,
      pm25,
      wind,
      moonIllum: moonMid.illumination,
      moonExposure: exposure,
    });

    // 그 밤 대표 weather_code (자정 무렵, 없으면 첫 샘플)
    const repIdx = idxs.find((k) => hourly.time[k].endsWith("T23:00")) ?? idxs[0] ?? -1;
    const repCode = repIdx >= 0 ? hourly.weather_code[repIdx] : cur.weather_code;
    const condition = classifySky(repCode, cloud);

    forecast.push({
      date: evening,
      label: i === 0 ? "오늘" : WEEKDAYS[evening.getDay()],
      score: result.score,
      condition,
    });
  }

  // 현재 달 위치
  const moonNow = getMoonState(now, lat, lng);
  // 배경 하늘 상태는 "오늘 밤" 기준(점수·문구와 일치). 밝기(낮/밤)만 현재 시각 기준.
  const condition = forecast[0]?.condition ?? classifySky(cur.weather_code, cur.cloud_cover);

  // 태양 고도로 낮/밤/노을 판정 (지평선 ±7° 부근을 노을로)
  const sunAlt = getSunAltitude(now, lat, lng);
  const sunAltLater = getSunAltitude(new Date(now.getTime() + 10 * 60 * 1000), lat, lng);
  const TW = 0.12; // 약 6.9°
  let daypart: "day" | "night" | "dawn" | "dusk";
  if (sunAlt > TW) daypart = "day";
  else if (sunAlt < -TW) daypart = "night";
  else daypart = sunAltLater > sunAlt ? "dawn" : "dusk";

  return {
    location,
    tonight: {
      score: forecast[0].score,
      base: 0,
      penalties: { humidity: 0, pm25: 0, wind: 0, moon: 0 },
    },
    condition,
    isDay: cur.is_day === 1,
    daypart,
    temperature: Math.round(cur.temperature_2m),
    cloud: Math.round(cur.cloud_cover),
    humidity: Math.round(cur.relative_humidity_2m),
    wind: Math.round(cur.wind_speed_10m * 10) / 10,
    pressure: Math.round(cur.surface_pressure),
    pm25: Math.round(airAt(air, hourly.time, findCurrentIdx(hourly.time, cur.time))),
    nightCloud: Math.round(night0?.cloud ?? cur.cloud_cover),
    nightHumidity: Math.round(night0?.humidity ?? cur.relative_humidity_2m),
    nightWind: Math.round((night0?.wind ?? cur.wind_speed_10m) * 10) / 10,
    nightPm25: Math.round(night0?.pm25 ?? 0),
    sunrise: new Date(weather.daily.sunrise[0]),
    sunset: new Date(weather.daily.sunset[0]),
    moonIllum: moonNow.illumination,
    moonPhase: moonNow.phase,
    moonAltitude: moonNow.altitude,
    moonName: moonPhaseName(moonNow.phase),
    forecast,
    updatedAt: now,
  };
}

// 현재 시각에 가장 가까운 hourly 인덱스 한 개를 배열로 (대기질 현재값 추정)
function findCurrentIdx(times: string[], currentTime: string): number[] {
  const hourKey = currentTime.slice(0, 13); // YYYY-MM-DDTHH
  const i = times.findIndex((t) => t.slice(0, 13) === hourKey);
  return i >= 0 ? [i] : times.length > 0 ? [0] : [];
}

export function useStargazingData(location: SavedLocation | null) {
  const [data, setData] = useState<StargazingData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!location) return;
    setLoading(true);
    setError(null);
    try {
      const [weather, air] = await Promise.all([
        fetchWeather(location.latitude, location.longitude),
        fetchAir(location.latitude, location.longitude),
      ]);
      setData(buildData(location, weather, air));
    } catch (e) {
      setError(e instanceof Error ? e.message : "데이터를 불러오지 못했어요.");
    } finally {
      setLoading(false);
    }
  }, [location]);

  useEffect(() => {
    load();
  }, [load]);

  return { data, loading, error, reload: load };
}
