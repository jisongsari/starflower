import type { NightInputs, ScoreResult } from "../types";

const clamp = (x: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, x));

/**
 * 별 관측 지수
 *
 *   I = max(0, B - Δhum - Δpm - Δwind - Δmoon)
 *
 * - 운량이 기본 점수 B를 결정하고, 나머지 요소가 거기서 점수를 깎는 구조.
 * - 완전히 맑고 건조하고 미세먼지 없는 달 없는 밤 → 100점
 * - 완전히 흐리면 다른 조건과 무관하게 → 0점
 */
export function computeScore(input: NightInputs): ScoreResult {
  const { cloud, humidity, pm25, wind, moonIllum, moonExposure } = input;

  // 기본 점수: 운량 (구름이 조금만 껴도 체감이 크므로 1.5제곱으로 초반을 가파르게)
  const base = 100 * Math.pow(1 - clamp(cloud, 0, 100) / 100, 1.5);

  // 습도 페널티: 40% 이하 무패널티, 100%에서 최대 -20
  const dHumidity = 20 * Math.pow(Math.max(0, (humidity - 40) / 60), 1.5);

  // 미세먼지 페널티: 75μg/m³ 이상 최대 -10, 0.8제곱으로 낮은 농도에서도 민감
  const dPm25 = 10 * Math.pow(clamp(pm25 / 75, 0, 1), 0.8);

  // 바람 페널티: 3m/s 이하 무패널티, 15m/s 이상 최대 -7
  const dWind = 7 * clamp(Math.pow(Math.max(0, (wind - 3) / 12), 2), 0, 1);

  // 달 페널티: 밝은 면 비율 × 고도 노출도, 최대 -8
  const dMoon = 8 * clamp(moonIllum, 0, 1) * clamp(moonExposure, 0, 1);

  const score = clamp(
    base - dHumidity - dPm25 - dWind - dMoon,
    0,
    100
  );

  return {
    score: Math.round(score),
    base: Math.round(base),
    penalties: {
      humidity: Math.round(dHumidity * 10) / 10,
      pm25: Math.round(dPm25 * 10) / 10,
      wind: Math.round(dWind * 10) / 10,
      moon: Math.round(dMoon * 10) / 10,
    },
  };
}

// 점수 → 정성 평가 (한국어)
export function scoreVerdict(score: number): { label: string; tone: string } {
  if (score >= 80) return { label: "최상의 관측 조건", tone: "great" };
  if (score >= 60) return { label: "관측하기 좋아요", tone: "good" };
  if (score >= 40) return { label: "그럭저럭 볼 만해요", tone: "ok" };
  if (score >= 20) return { label: "관측이 어려워요", tone: "poor" };
  return { label: "오늘은 별 보기 힘들어요", tone: "bad" };
}

// 점수 → 색. 흰색으로 통일 (점수별 색 구분을 쓰려면 아래 주석 해제)
export function scoreColor(_score: number): string {
  return "#f5f7ff";
  // if (score >= 80) return "#7ee3c7";
  // if (score >= 60) return "#9fd98a";
  // if (score >= 40) return "#f2d479";
  // if (score >= 20) return "#f0a868";
  // return "#e87b7b";
}
