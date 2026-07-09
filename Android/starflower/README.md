# 별바라기 (Starflower) — Android

iOS / 웹 / macOS 판과 동일한 별 관측 지수 앱의 안드로이드 네이티브 구현.
Jetpack Compose + Retrofit/Moshi 기반.

## 열기 / 빌드

1. **Android Studio** (Koala 2024.1.1 이상 권장) 에서 `File → Open` 으로 이 폴더를 연다.
2. 첫 동기화 때 Gradle 8.9 를 자동으로 받는다. (인터넷 필요)
3. 실행: 상단의 `app` 구성 + 기기/에뮬레이터 선택 후 Run.

- 최소 지원: **Android 8.0 (API 26)**
- 컴파일/타겟 SDK: 35

## 폰트 (Pretendard) 적용법

지금은 시스템 기본 폰트로 동작하도록 해두었다. Pretendard 를 적용하려면:

1. [Pretendard 배포본](https://github.com/orioncactus/pretendard) 의 TTF 를 받아
   `app/src/main/res/font/` 에 아래 이름으로 넣는다.

   | weight | 파일명 |
   |---|---|
   | 100 | `pretendard_thin.ttf` |
   | 200 | `pretendard_extralight.ttf` |
   | 300 | `pretendard_light.ttf` |
   | 400 | `pretendard_regular.ttf` |
   | 500 | `pretendard_medium.ttf` |
   | 600 | `pretendard_semibold.ttf` |
   | 700 | `pretendard_bold.ttf` |

2. `ui/theme/Type.kt` 안의 `pretendardFamily()` 주석 블록을 해제한다.
3. `Type.kt` 의 `USE_PRETENDARD` 를 `true` 로 바꾸고, `AppFontFamily` 의
   `pretendardFamily()` 줄을 활성화(아래 `FontFamily.Default` 제거)한다.

## 현재 구현 상태 (골격 단계)

- [x] 프로젝트 구조 / Gradle / 매니페스트 / 테마 / 폰트 틀
- [x] 데이터 모델 (`model/Models.kt`)
- [x] 지수 계산 (`calc/ScoreCalculator.kt`) — iOS 와 동일 공식
- [x] 달 천문 계산 (`calc/MoonCalculator.kt`) — SunCalc 포팅, 섭동항·월출월몰 포함
- [x] 날씨/대기질 (`data/WeatherService.kt`) — Open-Meteo, past_days=1
- [x] 지오코딩 (`data/GeoService.kt`) — Nominatim + Open-Meteo 백업
- [x] 위치 저장 (`data/LocationStore.kt`) — DataStore (App Group 대응)
- [x] ViewModel (`ui/StargazingViewModel.kt`) — buildData 1:1 이식
- [x] 메인 화면 골격 (`ui/screens/MainScreen.kt`) — 점수/로딩/에러 표시

## 다음 단계 (예정)

- [ ] SkyBackground: 그라데이션 + 별(Canvas) + 구름(애니메이션) + 달(Canvas)
- [ ] ScoreHero / ForecastCard / DetailGrid 컴포넌트
- [ ] SearchOverlay (지역 검색)
- [ ] 홈 화면 위젯 (Glance) — 2x2 / 4x2
- [ ] 잠금화면 위젯 대응 검토
