import type { SkyCondition } from "../types";

export interface Theme {
  background: string; // 레이어드 CSS 그라데이션
  text: string;
  subText: string;
  cardBg: string;
  cardBorder: string;
  accent: string;
  starOpacity: number; // 별 밀도/밝기 0~1
  cloudOpacity: number; // 구름 농도 0~1
  cloudTint: string; // 구름 색
  showMoon: boolean;
  metaThemeColor: string;
}

// Open-Meteo weather_code + 운량 → 거친 하늘 상태
export function classifySky(weatherCode: number, cloud: number): SkyCondition {
  const c = weatherCode;
  if (c >= 95) return "rain"; // 뇌우
  if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "snow";
  if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return "rain";
  if (c === 45 || c === 48) return "fog";
  if (cloud < 15) return "clear";
  if (cloud < 50) return "partly";
  if (cloud < 85) return "cloudy";
  return "overcast";
}

export function themeFor(
  condition: SkyCondition,
  daypart: "day" | "night" | "dawn" | "dusk"
): Theme {
  if (daypart === "day") return dayTheme(condition);
  if (daypart === "night") return nightTheme(condition);
  // 새벽/노을: 노을이 보이는 하늘(맑음·구름조금·구름많음)만 그라데이션 적용
  const isDawn = daypart === "dawn";
  if (condition === "clear" || condition === "partly" || condition === "cloudy") {
    return twilightTheme(condition, isDawn);
  }
  // 흐림·안개·비·눈은 노을이 안 보이므로 일반 테마로
  return isDawn ? dayTheme(condition) : nightTheme(condition);
}

// ── 새벽/노을 테마 ────────────────────────────────────────
function twilightTheme(condition: SkyCondition, isDawn: boolean): Theme {
  const glass = {
    cardBg: "rgba(0,0,0,0.25)",
    cardBorder: "rgba(255,255,255,0.08)",
    text: "#f5f7ff",
    subText: "rgba(255,255,255,0.64)",
  };

  // 노을(dusk): 따뜻한 주황·장미빛 / 새벽(dawn): 조금 더 부드럽고 시원한 톤
  const background = isDawn
    ? [
        "radial-gradient(120% 78% at 50% 113%, rgba(255,200,150,0.50) 0%, rgba(240,170,170,0.22) 32%, rgba(240,170,170,0) 58%)",
        "linear-gradient(180deg, #16244a 0%, #3b3a6b 34%, #6f5688 56%, #b87f93 76%, #e3b48d 100%)",
      ].join(",")
    : [
        "radial-gradient(120% 78% at 50% 113%, rgba(255,170,120,0.55) 0%, rgba(255,150,140,0.25) 30%, rgba(255,150,140,0) 56%)",
        "linear-gradient(180deg, #14224e 0%, #3a3168 32%, #7a4f7e 55%, #c2727f 76%, #e7a576 100%)",
      ].join(",");

  const cloudOpacity = condition === "clear" ? 0 : condition === "partly" ? 0.4 : 0.7;
  const starOpacity =
    condition === "clear" ? (isDawn ? 0.12 : 0.18) : condition === "partly" ? 0.08 : 0;

  return {
    background,
    ...glass,
    accent: "#ffba8c",
    starOpacity,
    cloudOpacity,
    // 구름이 노을빛을 받도록 따뜻한 틴트
    cloudTint: isDawn ? "rgba(244,180,162,0.58)" : "rgba(242,152,142,0.6)",
    showMoon: condition === "clear" || condition === "partly",
    metaThemeColor: isDawn ? "#6f5688" : "#7a4f7e",
  };
}

// ── 밤 테마 ───────────────────────────────────────────────
function nightTheme(condition: SkyCondition): Theme {
  const glassDark = {
    cardBg: "rgba(0,0,0,0.25)",
    cardBorder: "rgba(255,255,255,0.08)",
    text: "#f5f7ff",
    subText: "rgba(255,255,255,0.64)",
  };

  switch (condition) {
    case "clear":
      // 깊은 남보라 밤하늘 + 지평선의 옅은 청록빛
      return {
        background: [
          "radial-gradient(135% 90% at 50% 118%, rgba(46,120,138,0.40) 0%, rgba(46,120,138,0) 42%)",
          "radial-gradient(120% 80% at 78% -10%, rgba(96,72,168,0.45) 0%, rgba(96,72,168,0) 50%)",
          "linear-gradient(178deg, #050616 0%, #0a0e2e 38%, #131a4d 72%, #1d2566 100%)",
        ].join(","),
        ...glassDark,
        accent: "#8ea2ff",
        starOpacity: 1,
        cloudOpacity: 0,
        cloudTint: "rgba(180,190,230,0.5)",
        showMoon: true,
        metaThemeColor: "#0a0e2e",
      };
    case "partly":
      return {
        background: [
          "radial-gradient(130% 85% at 50% 115%, rgba(70,96,150,0.40) 0%, rgba(70,96,150,0) 45%)",
          "linear-gradient(180deg, #0a1024 0%, #141d3e 55%, #243056 100%)",
        ].join(","),
        ...glassDark,
        accent: "#9bb0e0",
        starOpacity: 0.5,
        cloudOpacity: 0.42,
        cloudTint: "rgba(150,165,205,0.55)",
        showMoon: true,
        metaThemeColor: "#141d3e",
      };
    case "cloudy":
      return {
        background: "linear-gradient(180deg, #1a2030 0%, #262e3f 50%, #353e50 100%)",
        ...glassDark,
        subText: "rgba(220,226,240,0.58)",
        accent: "#aeb8cc",
        starOpacity: 0.14,
        cloudOpacity: 0.78,
        cloudTint: "rgba(120,132,158,0.7)",
        showMoon: false,
        metaThemeColor: "#262e3f",
      };
    case "overcast":
      return {
        background: "linear-gradient(180deg, #23272f 0%, #2f343d 50%, #3b414b 100%)",
        ...glassDark,
        accent: "#9aa3b2",
        starOpacity: 0,
        cloudOpacity: 1,
        cloudTint: "rgba(108,116,130,0.8)",
        showMoon: false,
        metaThemeColor: "#2f343d",
      };
    case "fog":
      return {
        background: "linear-gradient(180deg, #2a2c38 0%, #3a3a48 55%, #46444f 100%)",
        ...glassDark,
        accent: "#b3aec2",
        starOpacity: 0,
        cloudOpacity: 0.9,
        cloudTint: "rgba(150,148,166,0.7)",
        showMoon: false,
        metaThemeColor: "#3a3a48",
      };
    case "snow":
      return {
        background: "linear-gradient(180deg, #1f2738 0%, #313c52 55%, #4a5a76 100%)",
        ...glassDark,
        accent: "#cdd8f0",
        starOpacity: 0.1,
        cloudOpacity: 0.85,
        cloudTint: "rgba(180,192,216,0.7)",
        showMoon: false,
        metaThemeColor: "#313c52",
      };
    case "rain":
      return {
        background: "linear-gradient(180deg, #161d28 0%, #20303a 55%, #2b414a 100%)",
        ...glassDark,
        accent: "#8fb6c4",
        starOpacity: 0,
        cloudOpacity: 0.92,
        cloudTint: "rgba(96,116,128,0.75)",
        showMoon: false,
        metaThemeColor: "#20303a",
      };
  }
}

// ── 낮 테마 ───────────────────────────────────────────────
function dayTheme(condition: SkyCondition): Theme {
  const glassLightDark = {
    cardBg: "rgba(0,0,0,0.25)",
    cardBorder: "rgba(255,255,255,0.08)",
    text: "#f5f7ff",
    subText: "rgba(255,255,255,0.64)",
  };
  const glassDayBlue = {
    cardBg: "rgba(0,0,0,0.25)",
    cardBorder: "rgba(255,255,255,0.08)",
    text: "#f5f7ff",
    subText: "rgba(255,255,255,0.64)",
  };

  switch (condition) {
    case "clear":
      return {
        background: [
          "radial-gradient(90% 60% at 80% 6%, rgba(255,236,170,0.55) 0%, rgba(255,236,170,0) 40%)",
          "linear-gradient(180deg, #2f74c0 0%, #4f93d4 45%, #8fc0e8 100%)",
        ].join(","),
        ...glassDayBlue,
        accent: "#2f74c0",
        starOpacity: 0,
        cloudOpacity: 0,
        cloudTint: "rgba(255,255,255,0.8)",
        showMoon: false,
        metaThemeColor: "#4f93d4",
      };
    case "partly":
      return {
        background: "linear-gradient(180deg, #5a82b4 0%, #7d9fc6 50%, #aac3de 100%)",
        ...glassDayBlue,
        accent: "#3f6ba0",
        starOpacity: 0,
        cloudOpacity: 0.5,
        cloudTint: "rgba(255,255,255,0.92)",
        showMoon: false,
        metaThemeColor: "#7d9fc6",
      };
    case "cloudy":
    case "overcast":
      return {
        background: "linear-gradient(180deg, #748091 0%, #8b95a3 50%, #a3abb6 100%)",
        ...glassLightDark,
        accent: "#4a5568",
        starOpacity: 0,
        cloudOpacity: condition === "overcast" ? 1 : 0.75,
        cloudTint: "rgba(255,255,255,0.85)",
        showMoon: false,
        metaThemeColor: "#8b95a3",
      };
    case "fog":
      return {
        background: "linear-gradient(180deg, #9a9aa6 0%, #aeaeb8 50%, #c2c2ca 100%)",
        ...glassLightDark,
        accent: "#5a5a66",
        starOpacity: 0,
        cloudOpacity: 0.9,
        cloudTint: "rgba(255,255,255,0.8)",
        showMoon: false,
        metaThemeColor: "#aeaeb8",
      };
    case "snow":
      return {
        background: "linear-gradient(180deg, #8a9bb8 0%, #aebccf 50%, #d3dde9 100%)",
        ...glassLightDark,
        accent: "#5a6b88",
        starOpacity: 0,
        cloudOpacity: 0.8,
        cloudTint: "rgba(255,255,255,0.95)",
        showMoon: false,
        metaThemeColor: "#aebccf",
      };
    case "rain":
      return {
        background: "linear-gradient(180deg, #5f6f7e 0%, #76858f 50%, #909ca5 100%)",
        ...glassLightDark,
        accent: "#3c4a58",
        starOpacity: 0,
        cloudOpacity: 0.95,
        cloudTint: "rgba(235,240,245,0.8)",
        showMoon: false,
        metaThemeColor: "#76858f",
      };
  }
}

export const conditionLabel: Record<SkyCondition, string> = {
  clear: "맑음",
  partly: "구름 조금",
  cloudy: "구름 많음",
  overcast: "흐림",
  fog: "안개",
  rain: "비",
  snow: "눈",
};
