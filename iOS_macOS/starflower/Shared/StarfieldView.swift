//
//  StarfieldView.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import SwiftUI

struct StarfieldView: View {
    let opacity: Double

    @ObservedObject private var gate = RenderGate.shared

    /// 실행당 한 번만 생성. 인스턴스 프로퍼티였을 때는 상위 뷰가 재평가될 때마다
    /// 난수 5400번을 다시 돌려 별자리가 통째로 바뀌었다.
    private static let stars: [Star] = (0..<900).map { _ in
        Star(x: .random(in: 0...1), y: .random(in: 0...0.92),
             // ▼ 별 크기: 값을 키우면 별이 커진다 (0.7 = 배율, 0.2 = 최소크기)
             r: pow(Double.random(in: 0...1), 2.3) * 0.7 + 0.2,
             baseA: .random(in: 0.35...0.95),
             speed: .random(in: 0.4...2.0), phase: .random(in: 0...(2 * .pi)))
    }

    var body: some View {
        if opacity > 0.02 {
            GeometryReader { geo in
                let area = Double(geo.size.width) * Double(geo.size.height)
                // ▼ 별 개수: 나누는 수가 작을수록 별이 많아진다 (1300 = 적당, 600 = 너무 많음)
                let count = min(Self.stars.count, Int(area / 1300.0 * opacity))

                // 반짝임 주기가 3초 남짓이라 30fps로 충분하다.
                // 120Hz 디스플레이에서 별 250개를 매 프레임 다시 그리던 비용이 1/4로 줄어든다.
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !gate.isActive)) { tl in
                    Canvas { ctx, size in
                        let t = tl.date.timeIntervalSinceReferenceDate
                        for s in Self.stars.prefix(count) {
                            let tw = 0.55 + 0.45 * sin(t * s.speed + s.phase)
                            let a = s.baseA * tw * opacity
                            let x = s.x * size.width, y = s.y * size.height

                            // ▼ 빛무리: r > 0.55 인 별에만. 임계값을 낮추면 더 많은 별에 무리가 뜬다
                            if s.r > 0.55 {
                                let h = s.r * 3.6   // 무리 크기 배율
                                ctx.fill(
                                    Path(ellipseIn: CGRect(x: x - h, y: y - h, width: h * 2, height: h * 2)),
                                    with: .radialGradient(
                                        Gradient(colors: [
                                            Color.rgba(205, 222, 255, a * 0.55),  // 무리 밝기
                                            Color.rgba(205, 222, 255, 0)
                                        ]),
                                        center: CGPoint(x: x, y: y),
                                        startRadius: 0,
                                        endRadius: h
                                    )
                                )
                            }

                            // 별 본체
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: x - s.r, y: y - s.r, width: s.r * 2, height: s.r * 2)),
                                with: .color((s.r > 1.0 ? Color.rgba(220, 230, 255, 1) : .white).opacity(a))
                            )
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

private struct Star { let x, y, r, baseA, speed, phase: Double }
