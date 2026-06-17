import type { Theme } from "../lib/theme";
import Starfield from "./Starfield";
import Clouds from "./Clouds";
import Moon from "./Moon";

interface SkyBackgroundProps {
  theme: Theme;
  moonIllum: number;
  moonPhase: number;
  moonAltitude: number; // 라디안
}

export default function SkyBackground({
  theme,
  moonIllum,
  moonPhase,
  moonAltitude,
}: SkyBackgroundProps) {
  // 달은 지평선 위(고도>0)이고 테마가 허용할 때만 표시
  const moonVisible = theme.showMoon && moonAltitude > 0.02;
  // 고도가 높을수록 화면 위쪽에 배치
  const altFrac = Math.min(1, Math.max(0, Math.sin(moonAltitude)));
  const moonTop = 14 - altFrac * 6; // 8%~14%
  const moonSize = 104 + moonIllum * 34; // 보름에 가까울수록 조금 더 큼

  return (
    <div className="sky" style={{ background: theme.background }} aria-hidden>
      <Starfield opacity={theme.starOpacity} />
      {moonVisible && (
        <div
          className="moon-wrap"
          style={{ top: `${moonTop}%`, left: "11%" }}
        >
          <Moon illumination={moonIllum} waxing={moonPhase < 0.5} size={moonSize} />
        </div>
      )}
      <Clouds opacity={theme.cloudOpacity} tint={theme.cloudTint} />
      <div className="sky-vignette" />
    </div>
  );
}
