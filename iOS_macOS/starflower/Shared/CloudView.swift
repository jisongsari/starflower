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

    // 뷰 등장 시마다 새로 생성되는 랜덤 블롭 풀.
    // @State 초기값이므로 앱 실행(뷰 identity)마다 배치가 달라지고,
    // 세션 중 부모 재렌더링에는 유지되어 구름이 튀지 않는다.
    @State private var blobs: [Blob] = Self.makeBlobs()

    private struct Blob {
        let y: Double      // 화면 높이 비율
        let w: CGFloat     // 폭 (pt)
        let dur: Double    // 가로 순환 주기 (초)
        let o: Double      // 개별 불투명도
        let phase: Double  // 시작 위상 (0~1)
    }

    private static func makeBlobs() -> [Blob] {
        (0..<78).map { _ in
            Blob(y: .random(in: 0.02...0.46),
                 w: .random(in: 220...420),
                 dur: .random(in: 70...126),
                 o: .random(in: 0.45...0.9),
                 phase: .random(in: 0..<1))
        }
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
                        CloudBlob(tint: tint, width: b.w, o: b.o, dur: b.dur,
                                  screenW: w, y: h * b.y,
                                  phase: b.phase)
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
