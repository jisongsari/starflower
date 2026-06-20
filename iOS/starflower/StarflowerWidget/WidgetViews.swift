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

// ── 소형 위젯 ─────────────────────────────────────────────
struct SmallWidgetView: View {
    let entry: StargazingEntry

    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                colors: [Color(hex: "#050616"), Color(hex: "#131a4d")],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                // 위치명
                Text(entry.locationName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))

                Spacer()

                // 큰 점수
                HStack(alignment: .top, spacing: 1) {
                    Text("\(entry.score)")
                        .font(.system(size: 52, weight: .ultraLight))
                        .foregroundStyle(.white)
                    Text("%")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top, 8)
                }

                // 별보기 지수 레이블
                Text("별보기 지수")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                // 날씨 아이콘 + 평가
                HStack(spacing: 4) {
                    Image(systemName: conditionSymbol)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(ScoreCalculator.verdict(for: entry.score))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) {
            Color(hex: "#0a0e2e")
        }
    }

    private var conditionSymbol: String {
        switch entry.condition {
        case .clear:    return "moon.stars.fill"
        case .partly:   return "cloud.moon.fill"
        case .cloudy:   return "cloud.fill"
        case .overcast: return "smoke.fill"
        case .fog:      return "cloud.fog.fill"
        case .rain:     return "cloud.rain.fill"
        case .snow:     return "cloud.snow.fill"
        }
    }
}

// ── 중형 위젯 ─────────────────────────────────────────────
struct MediumWidgetView: View {
    let entry: StargazingEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#050616"), Color(hex: "#131a4d")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 0) {
                // 왼쪽: 점수
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.locationName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.65))

                    Spacer()

                    HStack(alignment: .top, spacing: 1) {
                        Text("\(entry.score)")
                            .font(.system(size: 56, weight: .ultraLight))
                            .foregroundStyle(.white)
                        Text("%")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.top, 10)
                    }

                    Text(ScoreCalculator.verdict(for: entry.score))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))

                    Spacer()
                }
                .padding(16)
                .frame(maxHeight: .infinity, alignment: .leading)

                Divider()
                    .background(.white.opacity(0.1))
                    .padding(.vertical, 16)

                // 오른쪽: 달 + 업데이트 시각
                VStack(alignment: .leading, spacing: 8) {
                    // 달
                    HStack(spacing: 8) {
                        MoonView(
                            illumination: entry.moonIllum,
                            waxing: entry.moonPhase < 0.5,
                            size: 36
                        )
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(Int(entry.moonIllum * 100))%")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(.white)
                            Text(ScoreCalculator.moonPhaseName(phase: entry.moonPhase))
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }

                    Divider()
                        .background(.white.opacity(0.1))

                    // 업데이트 시각
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                        Text(updateTimeString)
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()
                }
                .padding(16)
                .frame(maxHeight: .infinity, alignment: .leading)
            }
        }
        .containerBackground(for: .widget) {
            Color(hex: "#0a0e2e")
        }
    }

    private var updateTimeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm 기준"
        return f.string(from: entry.date)
    }
}
