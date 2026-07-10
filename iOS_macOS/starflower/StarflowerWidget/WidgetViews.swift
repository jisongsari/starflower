//
//  WidgetViews.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    var entry: StargazingEntry
    @Environment(\.widgetFamily) var family
    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// ── 위젯 배경: 그라데이션 + 상태별 은은한 효과 ────────────
private struct WidgetSky: View {
    let entry: StargazingEntry

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: stops),
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            // 맑은 밤: 별
            if entry.daypart == .night && entry.condition == .clear {
                WidgetStars()
            }
            // 맑은 낮: 연한 해
            if entry.daypart == .day && entry.condition == .clear {
                Circle()
                    .fill(RadialGradient(colors: [col(255,240,180).opacity(0.5), col(255,236,170).opacity(0)],
                                         center: .center, startRadius: 0, endRadius: 90))
                    .frame(width: 180, height: 180)
                    .blur(radius: 18)
                    .offset(x: 70, y: -46)
            }
            // 흐림/구름/비/눈: 은은한 구름 덩어리
            if [.cloudy, .overcast, .fog, .rain, .snow].contains(entry.condition) {
                WidgetClouds(tint: .white.opacity(0.18))
            } else if entry.condition == .partly {
                WidgetClouds(tint: .white.opacity(0.12))
            }
        }
    }

    private func col(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(.sRGB, red: r/255, green: g/255, blue: b/255, opacity: 1)
    }
    private var stops: [Gradient.Stop] {
        func s(_ c: Color, _ l: Double) -> Gradient.Stop { .init(color: c, location: l) }
        switch entry.daypart {
        case .night:
            switch entry.condition {
            case .clear:  return [s(col(8,10,34),0), s(col(20,27,77),0.6), s(col(33,42,110),1)]
            case .partly: return [s(col(12,18,44),0), s(col(28,38,78),1)]
            default:      return [s(col(26,32,48),0), s(col(48,56,74),1)]
            }
        case .day:
            switch entry.condition {
            case .clear:  return [s(col(64,128,200),0), s(col(140,185,228),1)]
            case .partly: return [s(col(96,134,184),0), s(col(168,193,220),1)]
            default:      return [s(col(120,132,150),0), s(col(168,177,189),1)]
            }
        case .dawn: return [s(col(38,52,98),0), s(col(120,96,140),0.55), s(col(224,176,140),1)]
        case .dusk: return [s(col(34,44,92),0), s(col(128,82,128),0.55), s(col(228,160,116),1)]
        }
    }
}

private struct WidgetStars: View {
    // ▼ 별 밀도: 나누는 수가 작을수록 별이 많아진다 (앱 StarfieldView 와 동일: 1300)
    private let density: Double = 1000

    private let stars: [(x: Double, y: Double, r: Double, a: Double)] = (0..<900).map { _ in
        (.random(in: 0...1), .random(in: 0...0.92),
         pow(Double.random(in: 0...1), 2.3) * 0.7 + 0.2,   // 앱과 동일한 크기 공식
         .random(in: 0.4...0.95))
    }

    private func sc(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> Color {
        Color(.sRGB, red: r/255, green: g/255, blue: b/255, opacity: a)
    }

    var body: some View {
        GeometryReader { geo in
            let area = Double(geo.size.width) * Double(geo.size.height)
            let count = min(stars.count, Int(area / density))
            Canvas { ctx, size in
                for s in stars.prefix(count) {
                    let a = s.a
                    let x = s.x * size.width, y = s.y * size.height

                    // 빛무리 (앱과 동일: r > 0.55, h = r*3.6, 밝기 a*0.55)
                    if s.r > 0.55 {
                        let h = s.r * 3.6
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x - h, y: y - h, width: h * 2, height: h * 2)),
                            with: .radialGradient(
                                Gradient(colors: [sc(205, 222, 255, a * 0.55), sc(205, 222, 255, 0)]),
                                center: CGPoint(x: x, y: y),
                                startRadius: 0,
                                endRadius: h
                            )
                        )
                    }

                    // 별 본체
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - s.r, y: y - s.r, width: s.r * 2, height: s.r * 2)),
                        with: .color(s.r > 1.0 ? sc(220, 230, 255, a) : .white.opacity(a))
                    )
                }
            }
        }
    }
}

private struct WidgetClouds: View {
    let tint: Color
    private let blobs: [(x: Double, y: Double, w: Double, o: Double)] = [
        (0.2, 0.18, 150, 0.9), (0.7, 0.10, 120, 0.7), (0.85, 0.55, 140, 0.5),
    ]
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(blobs.indices, id: \.self) { i in
                    let b = blobs[i]
                    Ellipse()
                        .fill(RadialGradient(colors: [tint.opacity(b.o), tint.opacity(0)],
                                             center: .center, startRadius: 0, endRadius: b.w * 0.5))
                        .frame(width: b.w, height: b.w * 0.5)
                        .blur(radius: 14)
                        .position(x: geo.size.width * b.x, y: geo.size.height * b.y)
                }
            }
        }
    }
}

private func symbol(_ c: SkyCondition) -> String {
    switch c {
    case .clear: return "moon.stars.fill"
    case .partly: return "cloud.moon.fill"
    case .cloudy, .overcast, .fog: return "cloud.fill"
    case .rain: return "cloud.rain.fill"
    case .snow: return "cloud.snow.fill"
    }
}
private func hhmm(_ d: Date?) -> String {
    guard let d else { return "—" }
    let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
}

// ── 2x2 ───────────────────────────────────────────────────
struct SmallWidgetView: View {
    let entry: StargazingEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.locationName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
            Spacer(minLength: 0)
            HStack(alignment: .top, spacing: 1) {
                Text("\(entry.score)").font(.system(size: 64, weight: .thin)).foregroundStyle(.white)
                Text("%").font(.system(size: 24, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85)).padding(.top, 10)
            }
            HStack(spacing: 5) {
                Image(systemName: symbol(entry.condition))
                    .font(.system(size: 13)).foregroundStyle(.white.opacity(0.8))
                Text(ScoreCalculator.verdict(for: entry.score))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8)).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
            Text("기온 \(Int(entry.temperature.rounded()))° · \(hhmm(entry.date))")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { WidgetSky(entry: entry) }
    }
}

// ── 4x2 ───────────────────────────────────────────────────
struct MediumWidgetView: View {
    let entry: StargazingEntry
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 12) {
                // 왼쪽 (40%)
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.locationName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                    Spacer(minLength: 0)
                    HStack(alignment: .top, spacing: 1) {
                        Text("\(entry.score)").font(.system(size: 58, weight: .thin)).foregroundStyle(.white)
                        Text("%").font(.system(size: 22, weight: .regular))
                            .foregroundStyle(.white.opacity(0.85)).padding(.top, 9)
                    }
                    HStack(spacing: 5) {
                        Image(systemName: symbol(entry.condition))
                            .font(.system(size: 12)).foregroundStyle(.white.opacity(0.8))
                        Text(ScoreCalculator.verdict(for: entry.score))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)
                    Text("\(hhmm(entry.date))")
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.5))
                }
                .frame(width: geo.size.width * 0.40, alignment: .leading)

                // 오른쪽 (60%)
                VStack(spacing: 10) {
                    // 달 + 월몰/월출
                    HStack(spacing: 8) {
                        MoonView(illumination: entry.moonIllum, waxing: entry.moonPhase < 0.5, size: 36)
                            .frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(Int((entry.moonIllum*100).rounded()))%")
                                .font(.system(size: 18, weight: .regular)).foregroundStyle(.white)
                            Text(entry.moonName)
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        Spacer(minLength: 0)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("월출")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.55))
                                Text(hhmm(entry.moonrise))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            HStack(spacing: 4) {
                                Text("월몰")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.55))
                                Text(hhmm(entry.moonset))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    let cols = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
                    LazyVGrid(columns: cols, spacing: 9) {
                        metric("일몰", hhmm(entry.sunset))
                        metric("일출", hhmm(entry.sunrise))
                        metric("운량", "\(Int(entry.nightCloud.rounded()))%")
                        metric("습도", "\(Int(entry.nightHumidity.rounded()))%")
                        metric("풍속", "\(String(format: "%.1f", entry.nightWind))㎧")
                        metric("기압", "\(Int(entry.pressure.rounded()))h")
                        metric("미세먼지", "\(Int(entry.nightPm25.rounded()))㎍")
                        metric("기온", "\(Int(entry.temperature.rounded()))°")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
        }
        .containerBackground(for: .widget) { WidgetSky(entry: entry) }
    }
    
    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.system(size: 9)).foregroundStyle(.white.opacity(0.55))
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(value).font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
        }
    }
}

// ── 잠금화면 원형 (점수) ──────────────────────────────────
struct CircularWidgetView: View {
    let entry: StargazingEntry
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    Text("\(entry.score)")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("%")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.top, 6)
                }
                Text(entry.locationName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// ── 잠금화면 직사각형 ──────────────────────────────────────
struct RectangularWidgetView: View {
    let entry: StargazingEntry
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // 윗줄: 점수 + 동네·날씨
            HStack(alignment: .center, spacing: 8) {
                HStack(alignment: .top, spacing: 1) {
                    Text("\(entry.score)")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.9)
                        .padding(.vertical, -3.3)
                    Text("%")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(.white.opacity(0.75))
                        .offset(y: 4.2)
                }
                .fixedSize()
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.locationName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    HStack(spacing: 3) {
                        Image(systemName: symbol(entry.condition))
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.75))
                            .minimumScaleFactor(0.8)
                        Text("기온 \(Int(entry.temperature.rounded()))°")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.75))
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            // 아랫줄: 한줄평
            Text(ScoreCalculator.verdict(for: entry.score))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(1)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .containerBackground(for: .widget) { Color.clear }
    }
}

// ── 잠금화면 원형 (달 위상) ───────────────────────────────
struct MoonCircularWidgetView: View {
    let entry: StargazingEntry
    var body: some View {
        ZStack {
            VStack(spacing: 5) {
                MoonLockView(
                    illumination: entry.moonIllum,
                    waxing: entry.moonPhase < 0.5,
                    size: 35
                )
                Text(entry.moonName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
            //.padding(.top, 3)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// ── 잠금화면 원형 (일출·일몰) ─────────────────────────────
struct SunCircularWidgetView: View {
    let entry: StargazingEntry
    var body: some View {
        VStack(spacing: 0) {
            Text("일몰")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            Text(hhmm(entry.sunset))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Text("일출")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 2)
            Text(hhmm(entry.sunrise))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .containerBackground(for: .widget) { Color.clear }
    }
}


let locName = "제주특별자치도도도"
let scor = 100

#Preview("작은거", as: .accessoryRectangular) {
    StarflowerCircularWidget()
} timeline: {
    StargazingEntry(
        date: .now, score: scor, locationName: locName,
        condition: .clear, daypart: .night,
        moonIllum: 0.3, moonPhase: 0.2, moonAltitude: 0.5,
        temperature: 12, pressure: 1013,
        nightCloud: 10, nightHumidity: 45, nightWind: 2.0, nightPm25: 15,
        sunrise: .now, sunset: .now, moonName: "초승달",
        moonrise: nil, moonset: nil
    )
}
#Preview("긴거", as: .accessoryRectangular) {
    StarflowerRectangularWidget()
} timeline: {
    StargazingEntry(
        date: .now, score: scor, locationName: locName,
        condition: .clear, daypart: .night,
        moonIllum: 0.3, moonPhase: 0.2, moonAltitude: 0.5,
        temperature: 12, pressure: 1013,
        nightCloud: 10, nightHumidity: 45, nightWind: 2.0, nightPm25: 15,
        sunrise: .now, sunset: .now, moonName: "초승달",
        moonrise: nil, moonset: nil
    )
}
#Preview("달", as: .accessoryRectangular) {
    StarflowerMoonWidget()
} timeline: {
    StargazingEntry(
        date: .now, score: scor, locationName: locName,
        condition: .clear, daypart: .night,
        moonIllum: 0.7, moonPhase: 0.1, moonAltitude: 0.5,
        temperature: 12, pressure: 1013,
        nightCloud: 10, nightHumidity: 45, nightWind: 2.0, nightPm25: 15,
        sunrise: .now, sunset: .now, moonName: "상현망간의 달",
        moonrise: nil, moonset: nil
    )
}
#Preview("해", as: .accessoryRectangular) {
    StarflowerSunWidget()
} timeline: {
    StargazingEntry(
        date: .now, score: scor, locationName: locName,
        condition: .clear, daypart: .night,
        moonIllum: 0.3, moonPhase: 0.2, moonAltitude: 0.5,
        temperature: 12, pressure: 1013,
        nightCloud: 10, nightHumidity: 45, nightWind: 2.0, nightPm25: 15,
        sunrise: .now, sunset: .now, moonName: "초승달",
        moonrise: nil, moonset: nil
    )
}
