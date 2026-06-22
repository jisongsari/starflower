//
//  MacWidgetView.swift
//  starflower
//
//  Created by 양지성 on 6/22/26.
//


import SwiftUI

struct MacWidgetView: View {
    let data: StargazingData

    var body: some View {
        ZStack {
            MacWidgetSky(condition: data.condition, daypart: data.daypart)
            HStack(spacing: 12) {
                // 왼쪽: 점수
                VStack(alignment: .leading, spacing: 0) {
                    Text(data.location.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                    Spacer(minLength: 0)
                    HStack(alignment: .top, spacing: 1) {
                        Text("\(data.score)").font(.system(size: 46, weight: .thin)).foregroundStyle(.white)
                        Text("%").font(.system(size: 18, weight: .regular))
                            .foregroundStyle(.white.opacity(0.85)).padding(.top, 7)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: symbol(data.condition)).font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(ScoreCalculator.verdict(for: data.score))
                            .font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)
                    Text("기온 \(Int(data.temperature.rounded()))°")
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.5))
                }
                .frame(width: 120, alignment: .leading)

                // 오른쪽: 달 + 8요소
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        MoonView(illumination: data.moonIllum, waxing: data.moonPhase < 0.5, size: 34)
                            .frame(width: 34, height: 34)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(Int((data.moonIllum*100).rounded()))%")
                                .font(.system(size: 16, weight: .light)).foregroundStyle(.white)
                            Text(data.moonName).font(.system(size: 10)).foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer(minLength: 0)
                    }
                    let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)
                    LazyVGrid(columns: cols, spacing: 7) {
                        metric("월몰", hhmm(data.moonset)); metric("월출", hhmm(data.moonrise))
                        metric("일몰", hhmm(data.sunset));  metric("일출", hhmm(data.sunrise))
                        metric("운량", "\(Int(data.nightCloud.rounded()))%")
                        metric("습도", "\(Int(data.nightHumidity.rounded()))%")
                        metric("풍속", "\(String(format: "%.1f", data.nightWind))㎧")
                        metric("미세", "\(Int(data.nightPm25.rounded()))㎍")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(14)
        }
        .frame(height: 168)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(label).font(.system(size: 9)).foregroundStyle(.white.opacity(0.55))
            Text(value).font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
        }
    }
    private func symbol(_ c: SkyCondition) -> String {
        switch c {
        case .clear: return "moon.stars.fill"; case .partly: return "cloud.moon.fill"
        case .cloudy, .overcast, .fog: return "cloud.fill"
        case .rain: return "cloud.rain.fill"; case .snow: return "cloud.snow.fill"
        }
    }
    private func hhmm(_ d: Date?) -> String {
        guard let d else { return "—" }
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
    }
}

// iOS WidgetSky를 그대로 옮긴 그라데이션 배경
struct MacWidgetSky: View {
    let condition: SkyCondition
    let daypart: Daypart
    var body: some View {
        LinearGradient(gradient: Gradient(stops: stops), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    private func c(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(.sRGB, red: r/255, green: g/255, blue: b/255, opacity: 1)
    }
    private var stops: [Gradient.Stop] {
        func s(_ col: Color, _ l: Double) -> Gradient.Stop { .init(color: col, location: l) }
        switch daypart {
        case .night:
            switch condition {
            case .clear:  return [s(c(8,10,34),0), s(c(20,27,77),0.6), s(c(33,42,110),1)]
            case .partly: return [s(c(12,18,44),0), s(c(28,38,78),1)]
            default:      return [s(c(26,32,48),0), s(c(48,56,74),1)]
            }
        case .day:
            switch condition {
            case .clear:  return [s(c(64,128,200),0), s(c(140,185,228),1)]
            case .partly: return [s(c(96,134,184),0), s(c(168,193,220),1)]
            default:      return [s(c(120,132,150),0), s(c(168,177,189),1)]
            }
        case .dawn: return [s(c(38,52,98),0), s(c(120,96,140),0.55), s(c(224,176,140),1)]
        case .dusk: return [s(c(34,44,92),0), s(c(128,82,128),0.55), s(c(228,160,116),1)]
        }
    }
}