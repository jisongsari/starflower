// 저장되는 위치 정보
export interface SavedLocation {
  name: string;
  admin1?: string; // 시/도
  country?: string;
  latitude: number;
  longitude: number;
}

// 지오코딩 검색 결과 한 건
export interface GeoResult extends SavedLocation {
  id: number;
}

// 하늘 상태를 거칠게 분류한 값 (배경 테마 결정에 사용)
export type SkyCondition =
  | "clear"
  | "partly"
  | "cloudy"
  | "overcast"
  | "fog"
  | "rain"
  | "snow";

// 지수 계산에 들어가는 한 밤의 평균 입력값
export interface NightInputs {
  cloud: number; // 운량 %
  humidity: number; // 상대습도 %
  pm25: number; // 초미세먼지 μg/m³
  wind: number; // 풍속 m/s
  moonIllum: number; // 달 밝은 면 비율 0~1
  moonExposure: number; // 밤 동안 평균 max(0, sin(고도)) 0~1
}

// 지수 계산 결과 (총점 + 각 요소 기여도)
export interface ScoreResult {
  score: number; // 0~100
  base: number; // 운량 기반 기본 점수
  penalties: {
    humidity: number;
    pm25: number;
    wind: number;
    moon: number;
  };
}

// 하루치 예보 카드에 쓰는 요약
export interface DayForecast {
  date: Date;
  label: string; // 오늘 / 토 / 일 ...
  score: number;
  condition: SkyCondition;
}

// 메인 화면에 필요한 모든 데이터
export interface StargazingData {
  location: SavedLocation;
  tonight: ScoreResult;
  condition: SkyCondition; // 현재(밤) 하늘 상태
  isDay: boolean;
  daypart: "day" | "night" | "dawn" | "dusk"; // 낮/밤/새벽/노을
  // 편의 정보 (현재값 기준)
  temperature: number;
  cloud: number;
  humidity: number;
  wind: number;
  pressure: number;
  pm25: number;
  // 오늘 밤(19~05시) 평균 — 점수 산출에 쓰인 값
  nightCloud: number;
  nightHumidity: number;
  nightWind: number;
  nightPm25: number;
  sunrise: Date;
  sunset: Date;
  // 달
  moonrise: Date | null;
  moonset: Date | null;
  moonIllum: number;
  moonPhase: number; // 0~1 (0/1=삭, 0.5=망)
  moonAltitude: number; // 라디안, 배경 표시용
  moonName: string; // 위상 이름
  // 예보
  forecast: DayForecast[];
  updatedAt: Date;
}
