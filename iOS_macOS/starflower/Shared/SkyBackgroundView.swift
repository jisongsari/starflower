//
//  SkyBackgroundView.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import SwiftUI

struct SkyBackgroundView: View {
    let condition: SkyCondition
    let daypart: Daypart
    let moonIllum: Double
    let moonPhase: Double
    let moonAltitude: Double
    var cloudCover: Double = 50   // 운량 % (0~100)

    private var theme: SkyTheme { SkyThemeProvider.theme(condition, daypart) }
    private var moonVisible: Bool { theme.showMoon && moonAltitude > 0.02 }
    private var moonTop: Double { 0.22 - min(1, max(0, sin(moonAltitude))) * 0.06 }
    private var moonSize: CGFloat { 104 + moonIllum * 34 }

    // 운량 0~1, 단 10% 이하는 0으로 (완전히 맑은 하늘)
    private var coverage: Double {
        let c = cloudCover / 100
        if c <= 0.10 { return 0 }
        // 10%~100%를 0~1로 재매핑 (10%에서 0, 100%에서 1)
        return max(0, min(1, (c - 0.10) / 0.90))
    }
    private var cloudOpacity: Double {
        if coverage <= 0 { return 0 }   // 구름 한 점 없음
        let base = theme.cloudOpacity
        if base <= 0.03 { return coverage * 0.5 }
        return min(1, base * (0.4 + 0.6 * coverage))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                SkyGradientLayer(condition: condition, daypart: daypart)
                StarfieldView(opacity: theme.starOpacity)
                if moonVisible {
                    MoonView(illumination: moonIllum, waxing: moonPhase < 0.5, size: moonSize)
                        .shadow(color: Color.rgba(248,244,224,0.25), radius: 24)
                        .position(x: geo.size.width * 0.18, y: geo.size.height * moonTop)
                }
                CloudView(opacity: cloudOpacity, tint: theme.cloudTint, coverage: coverage)
                LinearGradient(colors: [.clear, .black.opacity(0.28)],
                               startPoint: .center, endPoint: .bottom)
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}
