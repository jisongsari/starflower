//
//  StarfieldView.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import SwiftUI

struct StarfieldView: View {
    let opacity: Double
    private let stars: [Star] = (0..<600).map { _ in
        Star(x: .random(in: 0...1), y: .random(in: 0...0.92),
             r: pow(Double.random(in: 0...1), 2.2) * 1.5 + 0.3,
             baseA: .random(in: 0.35...0.95),
             speed: .random(in: 0.4...2.0), phase: .random(in: 0...(2 * .pi)))
    }

    var body: some View {
        if opacity > 0.02 {
            GeometryReader { geo in
                let area = Double(geo.size.width) * Double(geo.size.height)
                let count = min(stars.count, Int(area / 5200.0 * opacity))
                TimelineView(.animation) { tl in
                    Canvas { ctx, size in
                        let t = tl.date.timeIntervalSinceReferenceDate
                        for s in stars.prefix(count) {
                            let tw = 0.55 + 0.45 * sin(t * s.speed + s.phase)
                            let a = s.baseA * tw * opacity
                            let x = s.x * size.width, y = s.y * size.height
                            ctx.fill(Path(ellipseIn: CGRect(x: x-s.r, y: y-s.r, width: s.r*2, height: s.r*2)),
                                     with: .color((s.r > 1.1 ? Color.rgba(220,230,255,1) : .white).opacity(a)))
                            if s.r > 1.0 {
                                let h = s.r * 2.6
                                ctx.fill(Path(ellipseIn: CGRect(x: x-h, y: y-h, width: h*2, height: h*2)),
                                         with: .color(Color.rgba(220,230,255, a*0.25)))
                            }
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
