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

    private var theme: SkyTheme { SkyThemeProvider.theme(condition, daypart) }
    private var moonVisible: Bool { theme.showMoon && moonAltitude > 0.02 }
    private var moonTop: Double { 0.22 - min(1, max(0, sin(moonAltitude))) * 0.06 }
    private var moonSize: CGFloat { 104 + moonIllum * 34 }

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
                CloudView(opacity: theme.cloudOpacity, tint: theme.cloudTint)
                LinearGradient(colors: [.clear, .black.opacity(0.28)],
                               startPoint: .center, endPoint: .bottom)
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}
