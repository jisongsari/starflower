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
        HStack(spacing: 8) {
            // 왼쪽: 점수
            VStack(alignment: .leading, spacing: 0) {
                Text(data.location.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.8))
                Spacer(minLength: 0)
                HStack(alignment: .top, spacing: 1) {
                    Text("\(data.score)")
                        .font(.system(size: 54, weight: .thin))
                        .foregroundStyle(.primary)
                    Text("%")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.primary.opacity(0.85))
                        .padding(.top, 8)
                }
                HStack(spacing: 4) {
                    Image(systemName: symbol(data.condition)).font(.system(size: 11))
                        .foregroundStyle(.primary.opacity(0.8))
                    Text(ScoreCalculator.verdict(for: data.score))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.8))
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
                Text(hhmm(data.updatedAt))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.5))
            }
            .frame(width: 124, alignment: .leading)

            // 오른쪽: 달 + 월출월몰, 하단 8칸
            VStack(spacing: 8) {
                HStack(spacing: 5) {
                    MoonView(illumination: data.moonIllum,
                                 waxing: data.moonPhase < 0.5, size: 38)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(Int((data.moonIllum*100).rounded()))%")
                            .font(.system(size: 17, weight: .light)).foregroundStyle(.primary)
                        Text(data.moonName)
                            .font(.system(size: 10)).foregroundStyle(.primary.opacity(0.6))
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("월출").font(.system(size: 9)).foregroundStyle(.primary.opacity(0.55))
                            Text(hhmm(data.moonrise)).font(.system(size: 11, weight: .medium)).foregroundStyle(.primary)
                        }
                        HStack(spacing: 4) {
                            Text("월몰").font(.system(size: 9)).foregroundStyle(.primary.opacity(0.55))
                            Text(hhmm(data.moonset)).font(.system(size: 11, weight: .medium)).foregroundStyle(.primary)
                        }
                    }
                }

                let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
                LazyVGrid(columns: cols, spacing: 8) {
                    metric("일몰", hhmm(data.sunset))
                    metric("일출", hhmm(data.sunrise))
                    metric("운량", "\(Int(data.nightCloud.rounded()))%")
                    metric("습도", "\(Int(data.nightHumidity.rounded()))%")
                    metric("풍속", "\(String(format: "%.1f", data.nightWind))㎧")
                    metric("기압", "\(Int(data.pressure.rounded()))h")
                    metric("미세먼지", "\(Int(data.nightPm25.rounded()))㎍")
                    metric("기온", "\(Int(data.temperature.rounded()))°")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(label).font(.system(size: 9)).foregroundStyle(.primary.opacity(0.55))
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(value).font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary).lineLimit(1).minimumScaleFactor(0.6)
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
