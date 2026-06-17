import { useEffect, useMemo, useState } from "react";
import type { CSSProperties } from "react";
import { useLocation } from "./hooks/useLocation";
import { useStargazingData } from "./hooks/useStargazingData";
import { themeFor } from "./lib/theme";
import SkyBackground from "./components/SkyBackground";
import ScoreHero from "./components/ScoreHero";
import ForecastCard from "./components/ForecastCard";
import DetailGrid from "./components/DetailGrid";
import SearchOverlay from "./components/SearchOverlay";

export default function App() {
  const { location, setLocation } = useLocation();
  const { data, loading, error, reload } = useStargazingData(location);
  const [searchOpen, setSearchOpen] = useState(!location);

  // 저장된 위치가 없으면 검색을 강제로 띄움
  useEffect(() => {
    if (!location) setSearchOpen(true);
  }, [location]);

  // 데이터가 없을 땐 맑은 밤하늘을 기본 배경으로
  const theme = useMemo(
    () => (data ? themeFor(data.condition, data.daypart) : themeFor("clear", "night")),
    [data]
  );

  // 상단 바 색 동기화
  useEffect(() => {
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute("content", theme.metaThemeColor);
  }, [theme]);

  const locationLabel = location?.name ?? "위치 선택";

  return (
    <div
      className="app"
      style={
        {
          "--text": theme.text,
          "--sub-text": theme.subText,
          "--card-bg": theme.cardBg,
          "--card-border": theme.cardBorder,
          "--accent": theme.accent,
        } as CSSProperties
      }
    >
      <SkyBackground
        theme={theme}
        moonIllum={data?.moonIllum ?? 0.5}
        moonPhase={data?.moonPhase ?? 0.25}
        moonAltitude={data?.moonAltitude ?? 0.5}
      />

      <div className="content">
        <header className="topbar">
          <button className="location-btn" onClick={() => setSearchOpen(true)}>
            <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" strokeWidth="1.8">
              <path d="M12 21s7-6.3 7-11a7 7 0 1 0-14 0c0 4.7 7 11 7 11Z" />
              <circle cx="12" cy="10" r="2.4" />
            </svg>
            <span>{locationLabel}</span>
            <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="m6 9 6 6 6-6" />
            </svg>
          </button>
          {location && (
            <button className="refresh-btn" onClick={reload} aria-label="새로고침">
              <svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round">
                <path d="M20 11a8 8 0 1 0-.5 4M20 5v6h-6" />
              </svg>
            </button>
          )}
        </header>

        {error && location && (
          <div className="state-msg">
            <p>{error}</p>
            <button onClick={reload}>다시 시도</button>
          </div>
        )}

        {!data && loading && location && (
          <div className="state-msg">
            <div className="spinner" />
            <p>하늘을 살펴보는 중…</p>
          </div>
        )}

        {data && (
          <main className="main">
            <ScoreHero
              score={data.tonight.score}
              condition={data.condition}
              temperature={data.temperature}
            />
            <ForecastCard forecast={data.forecast} />
            <DetailGrid data={data} />
            <footer className="updated">
              {data.location.name}
              {data.location.admin1 ? ` · ${data.location.admin1}` : ""} · Open-Meteo · 경기과학고등학교
            </footer>
          </main>
        )}
      </div>

      <SearchOverlay
        open={searchOpen}
        dismissable={!!location}
        onClose={() => setSearchOpen(false)}
        onSelect={(loc) => {
          setLocation(loc);
          setSearchOpen(false);
        }}
      />
    </div>
  );
}
