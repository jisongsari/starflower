//
//  SkyTheme.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import SwiftUI

// 그라데이션 전용 헬퍼 (타입 추론 없이 명시적으로)
private func skyColor(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> Color {
    Color(.sRGB, red: r/255, green: g/255, blue: b/255, opacity: a)
}
private func skyStop(_ color: Color, _ loc: Double) -> Gradient.Stop {
    Gradient.Stop(color: color, location: CGFloat(loc))
}

struct SkyTheme {
    var starOpacity: Double
    var cloudOpacity: Double
    var cloudTint: Color
    var showMoon: Bool
}

struct SkyThemeProvider {
    static func theme(_ c: SkyCondition, _ dp: Daypart) -> SkyTheme {
        switch dp {
        case .day:   return day(c)
        case .night: return night(c)
        case .dawn, .dusk:
            if c == .clear || c == .partly || c == .cloudy { return twilight(c, dawn: dp == .dawn) }
            return dp == .dawn ? day(c) : night(c)
        }
    }

    static func night(_ c: SkyCondition) -> SkyTheme {
        switch c {
        case .clear:    return .init(starOpacity: 1,    cloudOpacity: 0,    cloudTint: .rgba(180,190,230,0.5),  showMoon: true)
        case .partly:   return .init(starOpacity: 0.5,  cloudOpacity: 0.42, cloudTint: .rgba(150,165,205,0.55), showMoon: true)
        case .cloudy:   return .init(starOpacity: 0.14, cloudOpacity: 0.78, cloudTint: .rgba(120,132,158,0.7),  showMoon: false)
        case .overcast: return .init(starOpacity: 0,    cloudOpacity: 1,    cloudTint: .rgba(108,116,130,0.8),  showMoon: false)
        case .fog:      return .init(starOpacity: 0,    cloudOpacity: 0.9,  cloudTint: .rgba(150,148,166,0.7),  showMoon: false)
        case .snow:     return .init(starOpacity: 0.1,  cloudOpacity: 0.85, cloudTint: .rgba(180,192,216,0.7),  showMoon: false)
        case .rain:     return .init(starOpacity: 0,    cloudOpacity: 0.92, cloudTint: .rgba(96,116,128,0.75),  showMoon: false)
        }
    }
    static func day(_ c: SkyCondition) -> SkyTheme {
        switch c {
        case .clear:    return .init(starOpacity: 0, cloudOpacity: 0,    cloudTint: .white.opacity(0.8),  showMoon: false)
        case .partly:   return .init(starOpacity: 0, cloudOpacity: 0.5,  cloudTint: .white.opacity(0.92), showMoon: false)
        case .cloudy:   return .init(starOpacity: 0, cloudOpacity: 0.75, cloudTint: .white.opacity(0.85), showMoon: false)
        case .overcast: return .init(starOpacity: 0, cloudOpacity: 1,    cloudTint: .white.opacity(0.85), showMoon: false)
        case .fog:      return .init(starOpacity: 0, cloudOpacity: 0.9,  cloudTint: .white.opacity(0.8),  showMoon: false)
        case .snow:     return .init(starOpacity: 0, cloudOpacity: 0.8,  cloudTint: .white.opacity(0.95), showMoon: false)
        case .rain:     return .init(starOpacity: 0, cloudOpacity: 0.95, cloudTint: .rgba(235,240,245,0.8), showMoon: false)
        }
    }
    static func twilight(_ c: SkyCondition, dawn: Bool) -> SkyTheme {
        let cloudOpacity = c == .clear ? 0.0 : c == .partly ? 0.55 : 0.7
        let starOpacity  = c == .clear ? (dawn ? 0.9 : 1) : c == .partly ? 0.2 : 0.0
        return .init(starOpacity: starOpacity, cloudOpacity: cloudOpacity,
                     cloudTint: dawn ? .rgba(244,180,162,0.58) : .rgba(242,152,142,0.6),
                     showMoon: c == .clear || c == .partly)
    }
}

// ── 배경 그라데이션 레이어 ────────────────────────────────
struct SkyGradientLayer: View {
    let condition: SkyCondition
    let daypart: Daypart

    var body: some View {
        ZStack {
            switch daypart {
            case .night: nightBG
            case .day:   dayBG
            case .dawn:  twilightBG(dawn: true)
            case .dusk:  twilightBG(dawn: false)
            }
        }
        .ignoresSafeArea()
    }

    private func linear(_ stops: [Gradient.Stop]) -> some View {
        LinearGradient(gradient: Gradient(stops: stops), startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
    private func radial(_ stops: [Gradient.Stop], cx: Double, cy: Double, r: Double) -> some View {
        EllipticalGradient(gradient: Gradient(stops: stops),
                           center: UnitPoint(x: cx, y: cy),
                           startRadiusFraction: 0, endRadiusFraction: r)
            .ignoresSafeArea()
    }

    @ViewBuilder private var nightBG: some View {
        switch condition {
        case .clear:
            linear([skyStop(skyColor(5,6,22), 0), skyStop(skyColor(10,14,46), 0.38),
                    skyStop(skyColor(19,26,77), 0.72), skyStop(skyColor(29,37,102), 1)])
            radial([skyStop(skyColor(96,72,168,0.45), 0), skyStop(skyColor(96,72,168,0), 0.5)],
                   cx: 0.78, cy: -0.10, r: 0.8)
            radial([skyStop(skyColor(46,120,138,0.40), 0), skyStop(skyColor(46,120,138,0), 0.42)],
                   cx: 0.5, cy: 1.18, r: 0.9)
        case .partly:
            linear([skyStop(skyColor(10,16,36), 0), skyStop(skyColor(20,29,62), 0.55),
                    skyStop(skyColor(36,48,86), 1)])
            radial([skyStop(skyColor(70,96,150,0.40), 0), skyStop(skyColor(70,96,150,0), 0.45)],
                   cx: 0.5, cy: 1.15, r: 0.85)
        case .cloudy:
            linear([skyStop(skyColor(26,32,48), 0), skyStop(skyColor(38,46,63), 0.5),
                    skyStop(skyColor(53,62,80), 1)])
        case .overcast:
            linear([skyStop(skyColor(35,39,47), 0), skyStop(skyColor(47,52,61), 0.5),
                    skyStop(skyColor(59,65,75), 1)])
        case .fog:
            linear([skyStop(skyColor(42,44,56), 0), skyStop(skyColor(58,58,72), 0.55),
                    skyStop(skyColor(70,68,79), 1)])
        case .snow:
            linear([skyStop(skyColor(31,39,56), 0), skyStop(skyColor(49,60,82), 0.55),
                    skyStop(skyColor(74,90,118), 1)])
        case .rain:
            linear([skyStop(skyColor(22,29,40), 0), skyStop(skyColor(32,48,58), 0.55),
                    skyStop(skyColor(43,65,74), 1)])
        }
    }

    @ViewBuilder private var dayBG: some View {
        switch condition {
        case .clear:
                    linear([skyStop(skyColor(47,116,192), 0), skyStop(skyColor(79,147,212), 0.45),
                            skyStop(skyColor(143,192,232), 1)])
                    GeometryReader { geo in
                        Circle()
                            .fill(RadialGradient(
                                colors: [skyColor(255,240,180, 0.9), skyColor(255,236,170, 0.0)],
                                center: .center, startRadius: 0, endRadius: 260))
                            .frame(width: 520, height: 520)
                            .blur(radius: 40)
                            .position(x: geo.size.width * 0.8, y: geo.size.height * 0.12)
                    }
                    .ignoresSafeArea()
        case .partly:
            linear([skyStop(skyColor(90,130,180), 0), skyStop(skyColor(125,159,198), 0.5),
                    skyStop(skyColor(170,195,222), 1)])
        case .cloudy, .overcast:
            linear([skyStop(skyColor(116,128,145), 0), skyStop(skyColor(139,149,163), 0.5),
                    skyStop(skyColor(163,171,182), 1)])
        case .fog:
            linear([skyStop(skyColor(154,154,166), 0), skyStop(skyColor(174,174,184), 0.5),
                    skyStop(skyColor(194,194,202), 1)])
        case .snow:
            linear([skyStop(skyColor(138,155,184), 0), skyStop(skyColor(174,188,207), 0.5),
                    skyStop(skyColor(211,221,233), 1)])
        case .rain:
            linear([skyStop(skyColor(95,111,126), 0), skyStop(skyColor(118,133,143), 0.5),
                    skyStop(skyColor(144,156,165), 1)])
        }
    }

    @ViewBuilder private func twilightBG(dawn: Bool) -> some View {
        if condition == .clear || condition == .partly || condition == .cloudy {
            if dawn {
                linear([skyStop(skyColor(22,36,74), 0), skyStop(skyColor(59,58,107), 0.34),
                        skyStop(skyColor(111,86,136), 0.56), skyStop(skyColor(184,127,147), 0.76),
                        skyStop(skyColor(227,180,141), 1)])
                radial([skyStop(skyColor(255,200,150,0.50), 0), skyStop(skyColor(240,170,170,0.22), 0.32),
                        skyStop(skyColor(240,170,170,0), 0.58)], cx: 0.5, cy: 1.13, r: 0.85)
            } else {
                linear([skyStop(skyColor(20,34,78), 0), skyStop(skyColor(58,49,104), 0.32),
                        skyStop(skyColor(122,79,126), 0.55), skyStop(skyColor(194,114,127), 0.76),
                        skyStop(skyColor(231,165,118), 1)])
                radial([skyStop(skyColor(255,170,120,0.55), 0), skyStop(skyColor(255,150,140,0.25), 0.30),
                        skyStop(skyColor(255,150,140,0), 0.56)], cx: 0.5, cy: 1.13, r: 0.85)
            }
        } else {
            if dawn { dayBG } else { nightBG }
        }
    }
}
