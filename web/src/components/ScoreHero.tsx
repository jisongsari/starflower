import { scoreColor, scoreVerdict } from "../lib/score";
import { conditionLabel } from "../lib/theme";
import type { SkyCondition } from "../types";

interface ScoreHeroProps {
  score: number;
  condition: SkyCondition;
  temperature: number;
}

export default function ScoreHero({ score, condition, temperature }: ScoreHeroProps) {
  const verdict = scoreVerdict(score);
  const color = scoreColor(score);

  return (
    <div className="hero">
      <div className="hero-eyebrow">오늘 밤 관측 지수</div>
      <div className="hero-score">
        <span className="hero-num" style={{ textShadow: `0 0 40px ${color}55` }}>
          {score}
        </span>
        <span className="hero-percent">%</span>
      </div>
      <div className="hero-verdict" style={{ color }}>
        {verdict.label}
      </div>
      <div className="hero-sub">
        {conditionLabel[condition]} · {temperature}°
      </div>
      <div className="hero-gauge">
        <div
          className="hero-gauge-fill"
          style={{
            width: `${score}%`,
            background: `linear-gradient(90deg, ${color}99, ${color})`,
          }}
        />
      </div>
      <div className="hero-note">오늘 밤 19-05시</div>
    </div>
  );
}
