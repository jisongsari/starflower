import SunCalc from "suncalc";

export interface MoonState {
  illumination: number; // 밝은 면 비율 0~1
  phase: number; // 0~1 (0/1=삭, 0.25=상현, 0.5=망, 0.75=하현)
  waxing: boolean; // 차오르는 중이면 true (오른쪽이 밝음, 북반구)
  altitude: number; // 라디안
  azimuth: number;
}

export function getMoonState(date: Date, lat: number, lng: number): MoonState {
  const illum = SunCalc.getMoonIllumination(date);
  const pos = SunCalc.getMoonPosition(date, lat, lng);
  return {
    illumination: illum.fraction,
    phase: illum.phase,
    waxing: illum.phase < 0.5,
    altitude: pos.altitude,
    azimuth: pos.azimuth,
  };
}

// 밤 동안 달이 하늘을 얼마나 밝히는지: 시간별 max(0, sin(고도)) 평균
export function moonExposureOverNight(
  start: Date,
  end: Date,
  lat: number,
  lng: number
): number {
  let sum = 0;
  let n = 0;
  const stepMs = 30 * 60 * 1000; // 30분 간격
  for (let t = start.getTime(); t <= end.getTime(); t += stepMs) {
    const pos = SunCalc.getMoonPosition(new Date(t), lat, lng);
    sum += Math.max(0, Math.sin(pos.altitude));
    n++;
  }
  return n > 0 ? sum / n : 0;
}

// 태양 고도 (라디안). 낮/밤/노을 판정에 사용
export function getSunAltitude(date: Date, lat: number, lng: number): number {
  return SunCalc.getPosition(date, lat, lng).altitude;
}

// 위상 이름 (한국어)
export function moonPhaseName(phase: number): string {
  const p = ((phase % 1) + 1) % 1;
  if (p < 0.03 || p > 0.97) return "삭 (그믐)";
  if (p < 0.22) return "초승달";
  if (p < 0.28) return "상현달";
  if (p < 0.47) return "차오르는 달";
  if (p < 0.53) return "보름달";
  if (p < 0.72) return "기우는 달";
  if (p < 0.78) return "하현달";
  return "그믐달";
}
