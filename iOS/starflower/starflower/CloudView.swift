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

    private let blobs: [(y: Double, w: CGFloat, dur: Double, delay: Double, o: Double)] = [
        (0.06, 360, 70,  0,   0.9),
        (0.16, 280, 95,  -30, 0.7),
        (0.30, 420, 120, -60, 0.55),
        (0.02, 240, 85,  -15, 0.6),
    ]

    var body: some View {
        if opacity > 0.03 {
            GeometryReader { geo in
                ZStack {
                    ForEach(blobs.indices, id: \.self) { i in
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
