interface MoonProps {
  illumination: number; // 0~1
  waxing: boolean; // true = 차오름(오른쪽 밝음)
  size: number; // px
}

// 달 위상을 실제 밝은 면 비율대로 그린다.
// 구성: (1) 원 전체를 어두운 면으로 채우고 (2) 햇빛 받는 반원을 밝게 칠한 뒤
// (3) 명암경계(터미네이터) 타원을 더하거나(상현 이후) 빼서(상현 이전) 위상 완성.
export default function Moon({ illumination, waxing, size }: MoonProps) {
  const R = 46;
  const c = 50;
  const illum = Math.max(0, Math.min(1, illumination));
  const tx = R * (1 - 2 * illum); // 터미네이터 타원 가로 반지름(부호 포함)
  const terminatorLit = tx < 0; // 보름 쪽(gibbous)이면 타원을 밝게

  // 햇빛 받는 반원 (북반구: 차오름→오른쪽, 기움→왼쪽)
  const litRect = waxing
    ? { x: c, w: R }
    : { x: c - R, w: R };

  const uid = `${Math.round(illum * 1000)}-${waxing ? "x" : "n"}`;
  const litColor = `url(#moonLit-${uid})`;
  const darkColor = "#2b3252";

  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 100 100"
      style={{ display: "block", overflow: "visible" }}
      aria-hidden
    >
      <defs>
        <radialGradient id={`moonLit-${uid}`} cx="42%" cy="38%" r="75%">
          <stop offset="0%" stopColor="#fbf8ec" />
          <stop offset="55%" stopColor="#f1ecd6" />
          <stop offset="100%" stopColor="#d6cfb4" />
        </radialGradient>
        <radialGradient id={`moonGlow-${uid}`} cx="50%" cy="50%" r="50%">
          <stop offset="55%" stopColor="rgba(248,244,224,0.55)" />
          <stop offset="100%" stopColor="rgba(248,244,224,0)" />
        </radialGradient>
        <clipPath id={`moonClip-${uid}`}>
          <circle cx={c} cy={c} r={R} />
        </clipPath>
      </defs>

      {/* 은은한 달무리 */}
      <circle
        cx={c}
        cy={c}
        r={R + 14}
        fill={`url(#moonGlow-${uid})`}
        opacity={0.35 + 0.5 * illum}
      />

      <g clipPath={`url(#moonClip-${uid})`}>
        {/* 어두운 면 (지구조) */}
        <circle cx={c} cy={c} r={R} fill={darkColor} />
        {/* 햇빛 받는 반원 */}
        <rect x={litRect.x} y={c - R} width={litRect.w} height={2 * R} fill={litColor} />
        {/* 터미네이터 타원 */}
        <ellipse
          cx={c}
          cy={c}
          rx={Math.abs(tx)}
          ry={R}
          fill={terminatorLit ? litColor : darkColor}
        />
        {/* 표면의 옅은 바다(mare) 질감 */}
        <ellipse cx={42} cy={40} rx={14} ry={10} fill="#cfc7a8" opacity={0.25} />
        <ellipse cx={60} cy={62} rx={9} ry={7} fill="#cbc3a4" opacity={0.2} />
        <circle cx={64} cy={36} r={4.5} fill="#c7bf9f" opacity={0.22} />
      </g>
    </svg>
  );
}
