import type { ReactNode } from "react";
import type { StargazingData } from "../types";
import Moon from "./Moon";

function hhmm(d: Date | null): string {
  if (!d) return "—";
  const h = d.getHours();
  const m = d.getMinutes();
  return `${h < 10 ? "0" + h : h}:${m < 10 ? "0" + m : m}`;
}

function pmLabel(pm: number): string {
  if (pm <= 15) return "좋음";
  if (pm <= 35) return "보통";
  if (pm <= 75) return "나쁨";
  return "매우 나쁨";
}

interface CardProps {
  icon: ReactNode;
  label: string;
  children: ReactNode;
}
function DetailCard({ icon, label, children }: CardProps) {
  return (
    <div className="card detail-card">
      <div className="detail-head">
        <span className="detail-icon">{icon}</span>
        <span className="detail-label">{label}</span>
      </div>
      <div className="detail-body">{children}</div>
    </div>
  );
}

const ic = (path: string) => (
  <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
    <path d={path} />
  </svg>
);

export default function DetailGrid({ data }: { data: StargazingData }) {
  return (
    <section className="detail-grid">
      <DetailCard
        icon={ic("M3 18h18M12 2v3M5.6 9.6 4 8m14.4 1.6L20 8M8 18a4 4 0 0 1 8 0")}
        label="일몰"
      >
        <div className="detail-value">{hhmm(data.sunset)}</div>
        <div className="detail-sub">일출 {hhmm(data.sunrise)}</div>
      </DetailCard>

      <DetailCard icon={ic("M12 3a6 6 0 1 0 6 9 8 8 0 1 1-6-9Z")} label="월출">
        <div className="detail-value">{hhmm(data.moonrise)}</div>
        <div className="detail-sub">월몰 {hhmm(data.moonset)}</div>
      </DetailCard>

      <DetailCard icon={ic("M12 3a6 6 0 1 0 6 9 8 8 0 1 1-6-9Z")} label="달 위상">
        <div className="detail-moon-row">
          <Moon illumination={data.moonIllum} waxing={data.moonPhase < 0.5} size={46} />
          <div>
            <div className="detail-value">{Math.round(data.moonIllum * 100)}%</div>
            <div className="detail-sub moon-name">{data.moonName}</div>
          </div>
        </div>
      </DetailCard>

      <DetailCard icon={ic("M6 16a4 4 0 0 1 .5-7.97A5 5 0 0 1 16 8a3.5 3.5 0 0 1 .5 7H6Z")} label="운량">
        <div className="detail-value">{data.nightCloud}%</div>
        <div className="detail-sub">
          오늘 밤 · {data.nightCloud < 30 ? "맑음" : data.nightCloud < 70 ? "구름 조금" : "구름 많음"}
        </div>
      </DetailCard>

      <DetailCard icon={ic("M12 3s5 6 5 10a5 5 0 0 1-10 0c0-4 5-10 5-10Z")} label="습도">
        <div className="detail-value">{data.nightHumidity}%</div>
        <div className="detail-sub">
          오늘 밤 · {data.nightHumidity < 50 ? "건조" : data.nightHumidity < 75 ? "보통" : "습함"}
        </div>
      </DetailCard>

      <DetailCard icon={ic("M4 10h11a3 3 0 1 0-3-3M4 14h14a3 3 0 1 1-3 3")} label="풍속">
        <div className="detail-value">{data.nightWind}<span className="unit"> m/s</span></div>
        <div className="detail-sub">
          오늘 밤 · {data.nightWind < 3 ? "잔잔" : data.nightWind < 8 ? "약풍" : "강풍"}
        </div>
      </DetailCard>

      <DetailCard icon={ic("M3 12h18M3 7h18M3 17h12")} label="기압">
        <div className="detail-value">{data.pressure}<span className="unit"> hPa</span></div>
        <div className="detail-sub">지금 · 해면기압</div>
      </DetailCard>

      <DetailCard icon={ic("M3 8h12a3 3 0 1 0-3-3M3 12h16M3 16h10a3 3 0 1 1-3 3")} label="미세먼지">
        <div className="detail-value">{data.nightPm25}<span className="unit"> ㎍/㎥</span></div>
        <div className="detail-sub">오늘 밤 · {pmLabel(data.nightPm25)}</div>
      </DetailCard>
    </section>
  );
}
