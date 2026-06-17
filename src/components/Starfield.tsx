import { useEffect, useRef } from "react";

interface StarfieldProps {
  opacity: number; // 0~1 (운량 반영, 0이면 안 그림)
}

interface Star {
  x: number;
  y: number;
  r: number;
  baseA: number;
  twinkleSpeed: number;
  phase: number;
}

export default function Starfield({ opacity }: StarfieldProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const rafRef = useRef<number>(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || opacity <= 0.02) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    let w = 0;
    let h = 0;
    let stars: Star[] = [];
    const dpr = Math.min(window.devicePixelRatio || 1, 2);

    const build = () => {
      w = canvas.clientWidth;
      h = canvas.clientHeight;
      canvas.width = w * dpr;
      canvas.height = h * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      // 밀도는 화면 면적 + 운량(opacity)에 비례
      const count = Math.floor((w * h) / 5200 * opacity);
      stars = Array.from({ length: count }, () => {
        const r = Math.random() ** 2.2 * 1.5 + 0.3; // 작은 별이 다수
        return {
          x: Math.random() * w,
          y: Math.random() * h * 0.92,
          r,
          baseA: 0.35 + Math.random() * 0.6,
          twinkleSpeed: 0.4 + Math.random() * 1.6,
          phase: Math.random() * Math.PI * 2,
        };
      });
    };

    const draw = (t: number) => {
      ctx.clearRect(0, 0, w, h);
      for (const s of stars) {
        const tw = reduce ? 1 : 0.55 + 0.45 * Math.sin(t * 0.001 * s.twinkleSpeed + s.phase);
        const a = s.baseA * tw * opacity;
        ctx.globalAlpha = a;
        // 살짝 푸른빛 도는 흰 별
        ctx.fillStyle = s.r > 1.1 ? "#dce6ff" : "#ffffff";
        ctx.beginPath();
        ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
        ctx.fill();
        // 밝은 별엔 옅은 후광
        if (s.r > 1.0) {
          ctx.globalAlpha = a * 0.25;
          ctx.beginPath();
          ctx.arc(s.x, s.y, s.r * 2.6, 0, Math.PI * 2);
          ctx.fill();
        }
      }
      ctx.globalAlpha = 1;
      if (!reduce) rafRef.current = requestAnimationFrame(draw);
    };

    build();
    if (reduce) {
      draw(0);
    } else {
      rafRef.current = requestAnimationFrame(draw);
    }
    const onResize = () => build();
    window.addEventListener("resize", onResize);
    return () => {
      cancelAnimationFrame(rafRef.current);
      window.removeEventListener("resize", onResize);
    };
  }, [opacity]);

  if (opacity <= 0.02) return null;
  return <canvas ref={canvasRef} className="starfield" />;
}
