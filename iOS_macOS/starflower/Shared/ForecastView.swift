//
//  ForecastView.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import SwiftUI

struct ForecastView: View {
    let forecast: [DayForecast]
    private let text = Color.rgba(245,247,255,1)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("앞으로 3일 관측 지수")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.64))
                .padding(.horizontal, 18).padding(.top, 15).padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(forecast.enumerated()), id: \.element.id) { i, day in
                    if i > 0 {
                        Rectangle().fill(.white.opacity(0.06)).frame(height: 1)
                    }
                    HStack(spacing: 12) {
                        Text(day.label)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(text).frame(width: 34, alignment: .leading)
                        Image(systemName: symbol(day.condition))
                            .font(.system(size: 16)).foregroundStyle(text.opacity(0.9))
                            .frame(width: 26)
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.13))
                                    .frame(height: 6)
                                Capsule().fill(text)
                                    .frame(
                                        width: max(4, g.size.width * CGFloat(day.score) / 100),
                                        height: 6
                                    )
                            }
                        }.frame(height: 7)
                        Text("\(day.score)%")
                            .font(.system(size: 16, weight: .regular)).monospacedDigit()
                            .foregroundStyle(text).frame(width: 44, alignment: .trailing)
                    }
                    .padding(.vertical, 9)
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 8)
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
}
