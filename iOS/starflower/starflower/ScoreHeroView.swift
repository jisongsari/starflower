//
//  ScoreHeroView.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import SwiftUI

struct ScoreHeroView: View {
    let score: Int
    let condition: SkyCondition
    let temperature: Double

    private let text = Color.rgba(245,247,255,1)
    private var sub: Color { .white.opacity(0.64) }

    var body: some View {
        VStack(spacing: 0) {
            Text("오늘 밤 관측 지수")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(sub)
                .padding(.bottom, 2)

            HStack(alignment: .top, spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 128, weight: .ultraLight))
                    .tracking(-5)
                    .foregroundStyle(text)
                    .minimumScaleFactor(0.5).lineLimit(1)
                Text("%")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(text.opacity(0.85))
                    .padding(.top, 22)
            }
            .padding(.top, 4)

            Text(ScoreCalculator.verdict(for: score))
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(text)
                .padding(.top, 2)

            Text("\(ScoreCalculator.conditionLabel(condition)) · \(Int(temperature))°")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(sub)
                .padding(.top, 5)

            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.14)).frame(width: 220, height: 6)
                Capsule().fill(text).frame(width: 220 * CGFloat(score) / 100, height: 6)
                    .animation(.easeOut(duration: 0.8), value: score)
            }
            .padding(.top, 16)

            Text("오늘 밤 19-05시")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(sub.opacity(0.8))
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
