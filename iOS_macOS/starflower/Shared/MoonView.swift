//
//  MoonView.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import SwiftUI

struct MoonView: View {
    let illumination: Double
    let waxing: Bool
    let size: CGFloat

    var body: some View {
        Canvas { ctx, cs in
            let k = size / 100
            let cx = cs.width / 2, cy = cs.height / 2
            let R = 46 * k
            func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: cx + (x-50)*k, y: cy + (y-50)*k) }
            let illum = min(max(illumination, 0), 1)
            let dark = Color.rgba(43,50,82,1)
            let lit  = Color.rgba(241,236,214,1)

            // 달무리 (클립 없음)
            let glowR = R + 14*k
            ctx.fill(Path(ellipseIn: CGRect(x: cx-glowR, y: cy-glowR, width: glowR*2, height: glowR*2)),
                with: .radialGradient(Gradient(colors: [Color.rgba(248,244,224, 0.55*(0.35+0.5*illum)), .rgba(248,244,224,0)]),
                    center: CGPoint(x: cx, y: cy), startRadius: R*0.55, endRadius: glowR))

            let moon = Path(ellipseIn: CGRect(x: cx-R, y: cy-R, width: R*2, height: R*2))
            var c = ctx
            c.clip(to: moon)
            c.fill(moon, with: .color(dark))

            // 햇빛 받는 반원
            let rx0 = waxing ? cx : cx - R
            c.fill(Path(CGRect(x: rx0, y: cy-R, width: R, height: R*2)), with: .color(lit))

            // 터미네이터 타원
            let tx = R * (1 - 2*illum)
            let tEllipse = Path(ellipseIn: CGRect(x: cx-abs(tx), y: cy-R, width: abs(tx)*2, height: R*2))
            c.fill(tEllipse, with: .color(tx < 0 ? lit : dark))

            // 바다(mare) 질감
            c.fill(Path(ellipseIn: CGRect(x: pt(42,40).x - 14*k, y: pt(42,40).y - 10*k, width: 28*k, height: 20*k)),
                   with: .color(Color.rgba(207,199,168,0.25)))
            c.fill(Path(ellipseIn: CGRect(x: pt(60,62).x - 9*k, y: pt(60,62).y - 7*k, width: 18*k, height: 14*k)),
                   with: .color(Color.rgba(203,195,164,0.2)))
            c.fill(Path(ellipseIn: CGRect(x: pt(64,36).x - 4.5*k, y: pt(64,36).y - 4.5*k, width: 9*k, height: 9*k)),
                   with: .color(Color.rgba(199,191,159,0.22)))
        }
        .frame(width: size * 1.4, height: size * 1.4)
    }
}
