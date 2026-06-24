//
//  CloudView.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import SwiftUI

struct CloudView: View {
    let opacity: Double
    let tint: Color
    var coverage: Double = 1

    private let blobs: [(y: Double, w: CGFloat, dur: Double, o: Double)] = [
        (0.04, 360, 70,  0.9),  (0.10, 260, 88,  0.65), (0.16, 280, 95,  0.7),
        (0.22, 320, 105, 0.55), (0.28, 300, 110, 0.6),  (0.30, 420, 120, 0.5),
        (0.36, 240, 80,  0.7),  (0.42, 380, 115, 0.5),  (0.02, 240, 85,  0.6),
        (0.13, 340, 100, 0.55), (0.25, 220, 78,  0.7),  (0.38, 300, 108, 0.5),
        (0.07, 300, 92,  0.6),  (0.19, 360, 112, 0.5),  (0.33, 260, 84,  0.65),
        (0.45, 340, 118, 0.45), (0.09, 220, 76,  0.7),  (0.21, 400, 125, 0.45),
        (0.27, 280, 96,  0.6),  (0.40, 240, 82,  0.6),  (0.05, 320, 100, 0.5),
        (0.15, 260, 90,  0.65), (0.31, 380, 116, 0.5),  (0.43, 300, 104, 0.55),
        (0.06, 300, 84,  0.6),  (0.12, 380, 118, 0.5),  (0.18, 240, 80,  0.7),
        (0.24, 340, 110, 0.55), (0.32, 280, 94,  0.6),  (0.35, 400, 122, 0.45),
        (0.41, 260, 86,  0.65), (0.46, 320, 102, 0.5),  (0.03, 280, 90,  0.6),
        (0.11, 360, 114, 0.5),  (0.17, 300, 98,  0.6),  (0.23, 220, 76,  0.7),
        (0.29, 380, 120, 0.45), (0.37, 260, 88,  0.6),  (0.44, 340, 106, 0.5),
        (0.08, 320, 96,  0.55), (0.14, 240, 82,  0.7),  (0.20, 400, 124, 0.45),
        (0.26, 280, 92,  0.6),  (0.34, 360, 116, 0.5),  (0.39, 220, 78,  0.65),
        (0.47, 300, 100, 0.5),  (0.01, 340, 108, 0.55), (0.48, 260, 84,  0.6),
        (0.05, 340, 102, 0.55), (0.13, 280, 90,  0.6),  (0.21, 360, 118, 0.5),
        (0.29, 240, 80,  0.7),  (0.37, 320, 110, 0.55), (0.43, 380, 120, 0.45),
        (0.09, 300, 94,  0.6),  (0.17, 260, 86,  0.65), (0.25, 400, 122, 0.45),
        (0.33, 280, 92,  0.6),  (0.41, 340, 112, 0.5),  (0.47, 220, 78,  0.7),
        (0.03, 360, 116, 0.5),  (0.11, 300, 98,  0.6),  (0.19, 240, 82,  0.7),
        (0.27, 380, 124, 0.45), (0.35, 260, 88,  0.65), (0.44, 320, 104, 0.55),
        (0.07, 280, 90,  0.6),  (0.15, 400, 126, 0.45), (0.23, 300, 96,  0.6),
        (0.31, 340, 114, 0.5),  (0.39, 240, 80,  0.7),  (0.46, 360, 118, 0.5),
        (0.02, 300, 100, 0.55), (0.10, 260, 84,  0.65), (0.18, 380, 122, 0.45),
        (0.26, 320, 108, 0.55), (0.34, 280, 92,  0.6),  (0.42, 240, 82,  0.7),
    ]

    // 인덱스 기반 고정 난수 (0~1)
    private func rand(_ seed: Int, _ salt: Int) -> Double {
        var x = UInt64(bitPattern: Int64(seed &* 73856093 ^ salt &* 19349663)) &+ 0x9E3779B97F4A7C15
        x ^= x >> 30; x &*= 0xBF58476D1CE4E5B9
        x ^= x >> 27; x &*= 0x94D049BB133111EB
        x ^= x >> 31
        return Double(x % 100000) / 100000.0
    }

    var body: some View {
        if opacity > 0.03 {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let density = max(0, min(1, coverage))
                let maxByWidth = Int((w / 100).rounded(.up)) + 1
                let count = min(blobs.count, max(density > 0 ? 1 : 0,
                                                 Int((Double(maxByWidth) * 2 * density).rounded())))
                ZStack {
                    ForEach(0..<count, id: \.self) { i in
                        let b = blobs[i]
                        let jitterY = (rand(i, 7) - 0.5) * 0.06
                        CloudBlob(tint: tint, width: b.w, o: b.o, dur: b.dur,
                                  screenW: w, y: h * (b.y + jitterY),
                                  phase: rand(i, 3))
                            .transition(.opacity.animation(.easeInOut(duration: 0.7)))
                    }
                }
            }
            .opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

private struct CloudBlob: View {
    let tint: Color; let width: CGFloat; let o: Double
    let dur: Double; let screenW: CGFloat; let y: CGFloat
    let phase: Double

    @State private var t: Double = 0

    private var travel: CGFloat { screenW + width }
    private var startX: CGFloat { -width / 2 }
    private var x: CGFloat { startX + travel * CGFloat(t) }

    var body: some View {
        Ellipse()
            .fill(RadialGradient(colors: [tint.opacity(o), tint.opacity(0)],
                                 center: .center, startRadius: 0, endRadius: width * 0.5))
            .frame(width: width, height: width * 0.5)
            .blur(radius: 18)
            .position(x: x, y: y)
            .onAppear {
                t = phase
                let remaining = dur * (1 - phase.truncatingRemainder(dividingBy: 1))
                withAnimation(.linear(duration: remaining)) { t = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
                    t = 0
                    withAnimation(.linear(duration: dur).repeatForever(autoreverses: false)) {
                        t = 1
                    }
                }
            }
    }
}
