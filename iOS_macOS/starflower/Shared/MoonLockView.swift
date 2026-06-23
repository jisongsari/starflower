//
//  MoonLockView.swift
//  starflower
//
//  Created by 양지성 on 6/23/26.
//

import SwiftUI

// ── 잠금화면용 달 그림 ────────────────────────────────────
struct MoonLockView: View {
    let illumination: Double
    let waxing: Bool
    let size: CGFloat

    var body: some View {
        Canvas { ctx, cs in
            let R = size * 0.46
            let cx = cs.width / 2, cy = cs.height / 2
            let illum = min(max(illumination, 0), 1)
            let moon = Path(ellipseIn: CGRect(x: cx-R, y: cy-R, width: R*2, height: R*2))

            // 달무리
            let glowR = R + 8
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx-glowR, y: cy-glowR, width: glowR*2, height: glowR*2)),
                with: .radialGradient(
                    Gradient(colors: [.white.opacity(0.12), .white.opacity(0)]),
                    center: CGPoint(x: cx, y: cy), startRadius: R, endRadius: glowR)
            )

            // 어두운 면
            ctx.fill(moon, with: .color(.white.opacity(0.13)))

            // 밝은 면
            let lit = litPath(cx: cx, cy: cy, R: R, illum: illum, waxing: waxing)
            ctx.fill(lit, with: .color(.white))

            // 바다 질감
            ctx.clipToLayer(options: []) { $0.fill(lit, with: .color(.white)) }
            ctx.fill(Path(ellipseIn: CGRect(x: cx-R*0.30, y: cy-R*0.30, width: R*0.26, height: R*0.20)),
                     with: .color(.black.opacity(0.07)))
            ctx.fill(Path(ellipseIn: CGRect(x: cx+R*0.05, y: cy+R*0.10, width: R*0.18, height: R*0.14)),
                     with: .color(.black.opacity(0.06)))
        }
        .frame(width: size, height: size)
    }

    private func litPath(cx: CGFloat, cy: CGFloat, R: CGFloat, illum: CGFloat, waxing: Bool) -> Path {
        let k = 1 - 2 * illum   // -1~1: +면 초승(패임), -면 보름(볼록)

        var unit = Path()
        // 바깥 반원: 위(-90°) → 아래(90°)
        unit.move(to: CGPoint(x: 0, y: -1))
        unit.addArc(center: .zero, radius: 1,
                    startAngle: .degrees(-90), endAngle: .degrees(90),
                    clockwise: !waxing)

        // 터미네이터 반원: 아래(90°) → 위(270°), 방향 고정
        // 이 호를 x축으로 k배 스케일하면 타원호가 되고,
        // k 부호가 패임/볼록을 자동 결정 (음수면 거울처럼 반대로 휨)
        var term = Path()
        term.move(to: CGPoint(x: 0, y: 1))
        term.addArc(center: .zero, radius: 1,
                    startAngle: .degrees(90), endAngle: .degrees(270),
                    clockwise: !waxing)
        let sx = (abs(k) < 0.0015 ? 0.0015 : -k)
        unit.addPath(term.applying(CGAffineTransform(scaleX: sx, y: 1)))
        unit.closeSubpath()

        return unit.applying(CGAffineTransform(a: R, b: 0, c: 0, d: R, tx: cx, ty: cy))
    }
}
