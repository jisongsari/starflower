//
//  CloudView.swift
//  starflower
//

import SwiftUI

/// 떠다니는 구름.

struct CloudView: View {
    let opacity: Double
    let tint: Color
    var coverage: Double = 1
    
    @ObservedObject private var gate = RenderGate.shared
    
    private struct Blob {
        let y: Double       // 세로 위치 (0~1)
        let w: CGFloat      // 가로 지름
        let dur: Double     // 화면을 한 번 가로지르는 시간(초)
        let o: Double       // 덩어리 자체 농도
        let phase: Double   // 시작 위상 (0~1)
    }
    

    private static let pool: [Blob] = (0..<64).map { _ in
        Blob(y: .random(in: 0.01...0.47),
             w: .random(in: 380...680),
             dur: .random(in: 70...126),
             o: .random(in: 0.45...0.90),
             phase: .random(in: 0...1))
    }
    
    var body: some View {
        if opacity > 0.03 {
            GeometryReader { geo in
                let density = max(0, min(1, coverage))
                let maxByWidth = Double(geo.size.width / 100) + 1

                let capacity = maxByWidth * 2 * density

                let overscan: CGFloat = 32

                TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: !gate.isActive)) { tl in
                    Canvas { ctx, _ in
                        let t = tl.date.timeIntervalSinceReferenceDate
                        for i in 0..<Self.pool.count {
                            // capacity가 i를 넘는 정도를 0~1로 클램프.
                            // capacity가 i보다 1 이상 크면 완전히 보임(1),
                            // capacity가 i보다 작으면 안 보임(0),
                            // 그 사이는 선형 보간 — 이게 페이드 구간이다.
                            let fade = max(0, min(1, capacity - Double(i)))
                            if fade <= 0 { break }  // 이후 인덱스는 전부 0이므로 조기 종료

                            let b = Self.pool[i]
                            let travel = geo.size.width + b.w
                            let prog = (t / b.dur + b.phase).truncatingRemainder(dividingBy: 1)
                            let x = overscan + (-b.w / 2 + travel * prog)
                            let y = overscan + geo.size.height * b.y
                            let a = b.o * opacity * fade

                            ctx.drawLayer { layer in
                                layer.translateBy(x: x, y: y)
                                layer.scaleBy(x: 1, y: 0.5)
                                layer.fill(
                                    Path(ellipseIn: CGRect(x: -b.w / 2, y: -b.w / 2,
                                                           width: b.w, height: b.w)),
                                    with: .radialGradient(
                                        Gradient(stops: [
                                            .init(color: tint.opacity(a),        location: 0),
                                            .init(color: tint.opacity(a * 0.88), location: 0.25),
                                            .init(color: tint.opacity(a * 0.56), location: 0.50),
                                            .init(color: tint.opacity(a * 0.26), location: 0.70),
                                            .init(color: tint.opacity(a * 0.08), location: 0.85),
                                            .init(color: tint.opacity(0),        location: 1),
                                        ]),
                                        center: .zero, startRadius: 0, endRadius: b.w / 2)
                                )
                            }
                        }
                    }
                    .frame(width: geo.size.width + overscan * 2,
                           height: geo.size.height + overscan * 2)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .blur(radius: 14)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}
