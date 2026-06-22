interface CloudsProps {
  opacity: number; // 0~1
  tint: string;
}

// 부드러운 구름 덩어리가 천천히 흘러가는 레이어.
// 운량(opacity)이 낮으면 렌더하지 않음.
export default function Clouds({ opacity, tint }: CloudsProps) {
  if (opacity <= 0.03) return null;

  const blobs = [
    { top: "6%", size: 460, dur: 70, delay: 0, o: 0.9 },
    { top: "16%", size: 360, dur: 95, delay: -30, o: 0.7 },
    { top: "30%", size: 540, dur: 120, delay: -60, o: 0.55 },
    { top: "2%", size: 320, dur: 85, delay: -15, o: 0.6 },
  ];

  return (
    <div className="clouds" style={{ opacity }} aria-hidden>
      {blobs.map((b, i) => (
        <div
          key={i}
          className="cloud-blob"
          style={{
            top: b.top,
            width: b.size,
            height: b.size * 0.5,
            opacity: b.o,
            background: `radial-gradient(50% 50% at 50% 50%, ${tint} 0%, transparent 70%)`,
            animationDuration: `${b.dur}s`,
            animationDelay: `${b.delay}s`,
          }}
        />
      ))}
    </div>
  );
}
