//
//  StarflowerWidget.swift
//  StarflowerWidget
//
//  Created by 양지성 on 6/19/26.
//

import WidgetKit
import SwiftUI

// ── 위젯에 표시할 데이터 ──────────────────────────────────
struct StargazingEntry: TimelineEntry {
    let date: Date
    let score: Int
    let locationName: String
    let condition: SkyCondition
    let moonIllum: Double
    let moonPhase: Double
}

// ── 데이터 공급자 ─────────────────────────────────────────
struct Provider: TimelineProvider {

    // 프리뷰용 더미 데이터
    func placeholder(in context: Context) -> StargazingEntry {
        StargazingEntry(
            date: .now,
            score: 72,
            locationName: "수원시",
            condition: .clear,
            moonIllum: 0.3,
            moonPhase: 0.2
        )
    }

    // 위젯 갤러리 미리보기용
    func getSnapshot(in context: Context,
                     completion: @escaping (StargazingEntry) -> Void) {
        completion(placeholder(in: context))
    }

    // 실제 타임라인 — 1시간마다 갱신
    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<StargazingEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            // 1시간 후 다음 갱신
            let nextUpdate = Calendar.current.date(
                byAdding: .hour, value: 1, to: .now
            )!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    // ── 데이터 fetch + 계산 ───────────────────────────────
    private func fetchEntry() async -> StargazingEntry {
        let defaults = UserDefaults(suiteName: "group.com.songsari.starflower")
        let lat = defaults?.double(forKey: "latitude")  ?? 37.5665
        let lng = defaults?.double(forKey: "longitude") ?? 126.9780
        let name = defaults?.string(forKey: "locationName") ?? "위치 없음"

        // WeatherService로 직접 API 호출
        guard let weather = try? await WeatherService.shared.fetchWeather(lat: lat, lng: lng)
        else {
            return StargazingEntry(
                date: .now, score: 0,
                locationName: name,
                condition: .overcast,
                moonIllum: 0, moonPhase: 0
            )
        }

        let air = await WeatherService.shared.fetchAir(lat: lat, lng: lng)

        // 오늘 밤 구간 계산
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let todayEvening = hour < 6
            ? calendar.date(byAdding: .day, value: -1, to: now)!
            : now

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let eveningStr = formatter.string(from: todayEvening)
        let morningStr = formatter.string(
            from: calendar.date(byAdding: .day, value: 1, to: todayEvening)!
        )

        let indices = nightIndices(
            times: weather.hourly.time,
            eveningDate: eveningStr,
            morningDate: morningStr
        )

        let cloud    = average(indices.map { weather.hourly.cloudCover[$0] })
        let humidity = average(indices.map { weather.hourly.relativeHumidity2m[$0] })
        let wind     = average(indices.map { weather.hourly.windSpeed10m[$0] })
        let pm25     = airAverage(air: air, times: weather.hourly.time, indices: indices)

        let moonIllum = MoonCalculator.illumination(date: now)
        let exposure  = MoonCalculator.nightExposure(
            start: nightStart(eveningStr),
            end:   nightEnd(eveningStr),
            lat:   lat, lng: lng
        )

        let score = ScoreCalculator.compute(NightInputs(
            cloud: cloud, humidity: humidity,
            pm25: pm25, wind: wind,
            moonIllum: moonIllum.fraction,
            moonExposure: exposure
        ))

        let condition = classifySky(
            code: weather.current.weatherCode,
            cloud: cloud
        )

        return StargazingEntry(
            date: .now,
            score: score,
            locationName: name,
            condition: condition,
            moonIllum: moonIllum.fraction,
            moonPhase: moonIllum.phase
        )
    }

    // ── 유틸리티 (ViewModel과 동일) ───────────────────────
    private func nightIndices(times: [String],
                               eveningDate: String,
                               morningDate: String) -> [Int] {
        times.enumerated().compactMap { i, t in
            let date = String(t.prefix(10))
            let hourStr = t.dropFirst(11).prefix(2)
            guard let hour = Int(hourStr) else { return nil }
            if date == eveningDate && hour >= 19 { return i }
            if date == morningDate && hour <= 5  { return i }
            return nil
        }
    }

    private func nightStart(_ eveningDate: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.date(from: "\(eveningDate) 19:00") ?? Date()
    }

    private func nightEnd(_ eveningDate: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        let next = Calendar.current.date(
            byAdding: .day, value: 1,
            to: f.date(from: "\(eveningDate) 00:00") ?? Date()
        )!
        let nextStr = DateFormatter()
        nextStr.dateFormat = "yyyy-MM-dd"
        return f.date(from: "\(nextStr.string(from: next)) 05:00") ?? Date()
    }

    private func average(_ values: [Double]) -> Double {
        let valid = values.filter { $0.isFinite }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0, +) / Double(valid.count)
    }

    private func airAverage(air: AirResponse?,
                             times: [String],
                             indices: [Int]) -> Double {
        guard let air else { return 0 }
        let vals: [Double] = indices.compactMap { i in
            guard i < times.count else { return nil }
            let t = times[i]
            guard let j = air.hourly.time.firstIndex(of: t) else { return nil }
            return air.hourly.pm25[j]
        }
        return average(vals)
    }

    private func classifySky(code: Int, cloud: Double) -> SkyCondition {
        if code >= 95 { return .rain }
        if (71...77).contains(code) || code == 85 || code == 86 { return .snow }
        if (51...67).contains(code) || (80...82).contains(code) { return .rain }
        if code == 45 || code == 48 { return .fog }
        if cloud < 15 { return .clear }
        if cloud < 50 { return .partly }
        if cloud < 85 { return .cloudy }
        return .overcast
    }
}

// ── 위젯 등록 ─────────────────────────────────────────────
struct StarflowerWidget: Widget {
    let kind = "StarflowerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("별바라기")
        .description("오늘 밤 별보기 지수")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
