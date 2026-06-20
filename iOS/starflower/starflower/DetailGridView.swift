//
//  DetailGridView.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import SwiftUI

struct DetailGridView: View {
    let data: StargazingData
    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: cols, spacing: 12) {
            DetailCard(label: "일출 · 일몰", icon: "sunrise.fill") {
                Text(hhmm(data.sunrise)).detailValue()
                Text("일몰 \(hhmm(data.sunset))").detailSub()
            }
            DetailCard(label: "달 위상", icon: "moon.fill") {
                HStack(spacing: 12) {
                    MoonView(illumination: data.moonIllum, waxing: data.moonPhase < 0.5, size: 46)
                        .frame(width: 46, height: 46)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int((data.moonIllum * 100).rounded()))%").detailValue()
                        Text(data.moonName).detailSub()
                    }
                }
            }
            DetailCard(label: "기온", icon: "thermometer.medium") {
                Text("\(Int(data.temperature.rounded()))°").detailValue()
                Text("지금").detailSub()
            }
            DetailCard(label: "운량", icon: "cloud.fill") {
                Text("\(Int(data.nightCloud.rounded()))%").detailValue()
                Text("오늘 밤 · \(cloudLabel(data.nightCloud))").detailSub()
            }
            DetailCard(label: "습도", icon: "humidity.fill") {
                Text("\(Int(data.nightHumidity.rounded()))%").detailValue()
                Text("오늘 밤 · \(humLabel(data.nightHumidity))").detailSub()
            }
            DetailCard(label: "풍속", icon: "wind") {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", data.nightWind)).detailValue()
                    Text("m/s").detailUnit()
                }
                Text("오늘 밤 · \(windLabel(data.nightWind))").detailSub()
            }
            DetailCard(label: "기압", icon: "gauge.medium") {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(Int(data.pressure.rounded()))").detailValue()
                    Text("hPa").detailUnit()
                }
                Text("지금 · 해면기압").detailSub()
            }
            DetailCard(label: "미세먼지", icon: "aqi.medium") {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(Int(data.nightPm25.rounded()))").detailValue()
                    Text("㎍/㎥").detailUnit()
                }
                Text("오늘 밤 · \(ScoreCalculator.pmLabel(for: data.nightPm25))").detailSub()
            }
        }
    }

    private func hhmm(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
    }
    private func cloudLabel(_ v: Double) -> String { v < 30 ? "맑음" : v < 70 ? "구름 조금" : "구름 많음" }
    private func humLabel(_ v: Double) -> String { v < 50 ? "건조" : v < 75 ? "보통" : "습함" }
    private func windLabel(_ v: Double) -> String { v < 3 ? "잔잔" : v < 8 ? "약풍" : "강풍" }
}

struct DetailCard<Content: View>: View {
    let label: String; let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.64))
            VStack(alignment: .leading, spacing: 3) { content() }
        }
        .padding(.init(top: 14, leading: 16, bottom: 16, trailing: 16))
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .background {
                    ZStack {
                        Color.black
                            .opacity(0.3)
                            .blendMode(.softLight)
                    }
                }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(.white.opacity(0.08), lineWidth: 1))
    }
}

private extension Text {
    func detailValue() -> some View {
        self.font(.system(size: 30, weight: .light)).tracking(-0.6)
            .foregroundStyle(Color.rgba(245,247,255,1)).lineLimit(1).minimumScaleFactor(0.6)
    }
    func detailSub() -> some View {
        self.font(.system(size: 12.5, weight: .medium)).foregroundStyle(.white.opacity(0.64))
    }
    func detailUnit() -> some View {
        self.font(.system(size: 15, weight: .medium)).foregroundStyle(.white.opacity(0.55))
    }
}
