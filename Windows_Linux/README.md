# 별바라기 데스크탑 (Windows / Linux)

Compose Multiplatform 기반. 안드로이드 코드(Kotlin/Compose)를 최대한 재사용하고,
macOS 버전의 데스크탑 전용 동작(창 크기 상한, 자동실행)을 이식했다.
위젯 등 외부 연동 기능은 제외하고 앱 창만 구성했다.

## 실행 (개발 중 테스트)

```
./gradlew run          # Linux
gradlew.bat run         # Windows
```

## 배포용 패키지 만들기

**Windows에서 실행 → .msi 생성**
```
gradlew.bat packageMsi
```
결과물 위치: `build/compose/binaries/main/msi/`

**우분투(리눅스)에서 실행 → .deb 생성**
```
./gradlew packageDeb
```
결과물 위치: `build/compose/binaries/main/deb/`

각 OS에서 그 OS용 포맷만 만들어진다(크로스 컴파일 불가). Windows용 .msi는 Windows에서,
.deb는 리눅스에서 각각 한 번씩 빌드해야 한다.

## 요구 사항

- JDK 17 이상 (Temurin 등 아무 배포판이나 무관)
- Windows 10/11 또는 Ubuntu 20.04+ (다른 데비안 계열 배포판도 대체로 동작)

## 프로젝트 구조 / 무엇을 재사용했는지

- `calc/`, `model/`, `data/WeatherService.kt`, `data/GeoService.kt` — 안드로이드 코드에서 **한 글자도 안 바꾸고** 그대로 가져옴 (순수 Kotlin/JVM 코드라 데스크탑에서도 그대로 동작).
- `ui/components/` — 안드로이드 Compose 컴포넌트를 그대로 가져옴. 유일한 예외는 `DetailGrid.kt`에서 안드로이드 전용인 `PlatformTextStyle(includeFontPadding=false)`를 제거한 것(데스크탑엔 그 폰트 여백 문제 자체가 없음).
- `data/LocationStore.kt`, `data/RecentSearchStore.kt` — 안드로이드 DataStore 대신 `java.util.prefs.Preferences` 사용(데스크탑 표준 로컬 저장소).
- `ui/StargazingViewModel.kt` — `AndroidViewModel` 대신 순수 클래스 + 자체 `CoroutineScope`. 위젯 갱신 로직은 제거.
- `ui/theme/Type.kt` — 안드로이드 리소스 폰트(`R.font`) 대신 `resources/font/`에서 직접 로드.
- `desktop/LaunchAtLogin.kt` — macOS `SMAppService` 대응. Windows는 레지스트리 Run 키, 리눅스는 `~/.config/autostart/*.desktop` 파일로 구현.
- `Main.kt` — macOS `MainWindowController`의 동작(초기 크기 800×900, 최소 크기 500×650, 콘텐츠 폭 상한 600dp 가운데 정렬)을 이식.

## 아직 안 들어간 것 / 직접 붙이면 좋은 것

- **자동실행 UI**: `LaunchAtLogin.isEnabled`를 토글하는 설정 화면(체크박스 등)이 아직 없다. macOS `MacContentView`의 설정 패널을 참고해서 만들면 된다 — `LaunchAtLogin.isEnabled = true/false`로 바로 제어 가능.
- **트레이 아이콘**: macOS는 메뉴바 앱이 아니라 일반 창 앱이라 트레이 아이콘이 없었는데, 원하면 Compose Desktop의 `Tray` API로 추가할 수 있다.
- **앱 아이콘**: 지금은 기본 아이콘이 뜬다. `nativeDistributions` 블록에 `iconFile.set(...)`으로 `.ico`(Windows)/`.png`(Linux) 지정 가능.
