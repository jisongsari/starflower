import { scoreColor } from "../lib/score";
import { conditionLabel } from "../lib/theme";
import type { DayForecast } from "../types";

interface ForecastCardProps {
  forecast: DayForecast[];
}

// 하늘 상태별 작은 아이콘 (이모지 대신 간단한 SVG)
function SkyIcon({ condition }: { condition: DayForecast["condition"] }) {
  switch (condition) {
    case "clear":
      return (
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none">
          <path d="M14 4.5a6 6 0 1 0 5.5 9.2A7 7 0 0 1 14 4.5Z" fill="#e9e2c4" />
        </svg>
      );
    case "partly":
      return (
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none">
          <circle cx="9" cy="8" r="3.2" fill="#e9e2c4" />
          <path d="M7 17h9a3.2 3.2 0 0 0 .2-6.38A4.2 4.2 0 0 0 8.4 11 3 3 0 0 0 7 17Z" fill="#cdd4e2" />
        </svg>
      );
    case "cloudy":
    case "overcast":
    case "fog":
      return (
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none">
          <path d="M7 18h9.5a3.5 3.5 0 0 0 .2-6.99A4.6 4.6 0 0 0 8.2 11 3.4 3.4 0 0 0 7 18Z" fill="#c3cad8" />
        </svg>
      );
    case "rain":
      return (
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none">
          <path d="M7 15h9.5a3.5 3.5 0 0 0 .2-6.99A4.6 4.6 0 0 0 8.2 8 3.4 3.4 0 0 0 7 15Z" fill="#b7c0d2" />
          <path d="M9 17l-1 2.5M13 17l-1 2.5M17 17l-1 2.5" stroke="#8fb6e0" strokeWidth="1.6" strokeLinecap="round" />
        </svg>
      );
    case "snow":
      return (
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none">
          <path d="M7 15h9.5a3.5 3.5 0 0 0 .2-6.99A4.6 4.6 0 0 0 8.2 8 3.4 3.4 0 0 0 7 15Z" fill="#cdd6e6" />
          <circle cx="9" cy="18.5" r="1" fill="#eaf1fb" />
          <circle cx="13" cy="18.5" r="1" fill="#eaf1fb" />
          <circle cx="16.5" cy="18.5" r="1" fill="#eaf1fb" />
        </svg>
      );
  }
}

export default function ForecastCard({ forecast }: ForecastCardProps) {
  return (
    <section className="card forecast-card">
      <h2 className="card-title">앞으로 3일 관측 지수</h2>
      <div className="forecast-rows">
        {forecast.map((d, i) => {
          const color = scoreColor(d.score);
          return (
            <div className="forecast-row" key={i}>
              <span className="forecast-day">{d.label}</span>
              <span className="forecast-icon" title={conditionLabel[d.condition]}>
                <SkyIcon condition={d.condition} />
              </span>
              <div className="forecast-bar">
                <div
                  className="forecast-bar-fill"
                  style={{
                    width: `${Math.max(4, d.score)}%`,
                    background: `linear-gradient(90deg, ${color}88, ${color})`,
                  }}
                />
              </div>
              <span className="forecast-pct" style={{ color }}>
                {d.score}%
              </span>
            </div>
          );
        })}
      </div>
    </section>
  );
}
