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

    private let blobs: [(y: Double, w: CGFloat, dur: Double, delay: Double, o: Double)] = [
        (0.04, 360, 70,  0,    0.9),
        (0.10, 260, 88,  -70,  0.65),
        (0.16, 280, 95,  -30,  0.7),
        (0.22, 320, 105, -45,  0.55),
        (0.28, 300, 110, -20,  0.6),
        (0.30, 420, 120, -60,  0.5),
        (0.36, 240, 80,  -50,  0.7),
        (0.42, 380, 115, -35,  0.5),
        (0.02, 240, 85,  -15,  0.6),
        (0.13, 340, 100, -90,  0.55),
        (0.25, 220, 78,  -10,  0.7),
        (0.38, 300, 108, -75,  0.5),
        (0.07, 300, 92,  -25,  0.6),
        (0.19, 360, 112, -55,  0.5),
        (0.33, 260, 84,  -5,   0.65),
        (0.45, 340, 118, -80,  0.45),
        (0.09, 220, 76,  -40,  0.7),
        (0.21, 400, 125, -65,  0.45),
        (0.27, 280, 96,  -12,  0.6),
        (0.40, 240, 82,  -58,  0.6),
        (0.05, 320, 100, -85,  0.5),
        (0.15, 260, 90,  -33,  0.65),
        (0.31, 380, 116, -48,  0.5),
        (0.43, 300, 104, -22,  0.55),
    ]

    private var visibleCount: Int {
        let c = max(0, min(1, coverage))
        return max(1, Int((c * Double(blobs.count)).rounded()))
    }

    // 표시할 블롭 인덱스를 무작위로 (단, coverage 시드로 고정되어 깜빡임 없음)
    private var chosenIndices: [Int] {
        var seed = UInt64(coverage * 1000) &+ 0x9E3779B9
        func rand() -> UInt64 {
            seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17
            return seed
        }
        var idx = Array(blobs.indices)
        // Fisher–Yates 셔플
        for i in stride(from: idx.count - 1, to: 0, by: -1) {
            let j = Int(rand() % UInt64(i + 1))
            idx.swapAt(i, j)
        }
        return Array(idx.prefix(visibleCount))
    }

    var body: some View {
        if opacity > 0.03 {
            GeometryReader { geo in
                ZStack {
                    ForEach(chosenIndices, id: \.self) { i in
                        let b = blobs[i]
                        CloudBlob(tint: tint, width: b.w, o: b.o,
                                  dur: b.dur, delay: b.delay, screenW: geo.size.width)
                            .position(x: geo.size.width / 2, y: geo.size.height * b.y)
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
    let dur: Double; let delay: Double; let screenW: CGFloat
    @State private var x: CGFloat = 0

    var body: some View {
        Ellipse()
            .fill(RadialGradient(colors: [tint.opacity(o), tint.opacity(0)],
                                 center: .center, startRadius: 0, endRadius: width * 0.5))
            .frame(width: width, height: width * 0.5)
            .blur(radius: 18)
            .offset(x: x)
            .onAppear {
                x = -screenW * 0.55
                withAnimation(.linear(duration: dur).repeatForever(autoreverses: false).delay(delay)) {
                    x = screenW * 0.6
                }
            }
    }
}
