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
    let daypart: Daypart
    let moonIllum: Double
    let moonPhase: Double
    let moonAltitude: Double
    let temperature: Double
    let pressure: Double
    let nightCloud: Double
    let nightHumidity: Double
    let nightWind: Double
    let nightPm25: Double
    let sunrise: Date
    let sunset: Date
    let moonName: String
    let moonrise: Date?
    let moonset: Date?
}

// ── 데이터 공급자 ─────────────────────────────────────────
struct Provider: TimelineProvider {

    // 프리뷰용 더미 데이터
    func placeholder(in context: Context) -> StargazingEntry {
            dummyEntry()
        }
    
    private func dummyEntry() -> StargazingEntry {
            StargazingEntry(
                date: .now, score: 72, locationName: "수원시",
                condition: .clear, daypart: .night,
                moonIllum: 0.3, moonPhase: 0.2, moonAltitude: 0.5,
                temperature: 12, pressure: 1013,
                nightCloud: 10, nightHumidity: 45, nightWind: 2.0, nightPm25: 15,
                sunrise: .now, sunset: .now, moonName: "초승달",
                moonrise: .now, moonset: .now
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
        
        guard let wx = try? await WeatherService.shared.fetchWeather(lat: lat, lng: lng) else {
            return dummyEntry()
        }
        let air = await WeatherService.shared.fetchAir(lat: lat, lng: lng)
        
        let now = Date()
        let cal = Calendar.current
        let cur = wx.current
        let hourly = wx.hourly
        let hour = cal.component(.hour, from: now)
        let todayEvening = hour < 6 ? cal.date(byAdding: .day, value: -1, to: now)! : now
        
        func dateStr(_ d: Date) -> String {
            let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd"; return f.string(from: d)
        }
        let eStr = dateStr(todayEvening)
        let mStr = dateStr(cal.date(byAdding: .day, value: 1, to: todayEvening)!)
        let idxs: [Int] = hourly.time.enumerated().compactMap { i, t in
            let d = String(t.prefix(10))
            guard let h = Int(t.dropFirst(11).prefix(2)) else { return nil }
            if d == eStr && h >= 19 { return i }
            if d == mStr && h <= 5  { return i }
            return nil
        }
        func avg(_ v: [Double]) -> Double {
            let f = v.filter { $0.isFinite }; return f.isEmpty ? 0 : f.reduce(0,+)/Double(f.count)
        }
        let cloud = avg(idxs.map { hourly.cloudCover[$0] })
        let hum   = avg(idxs.map { hourly.relativeHumidity2m[$0] })
        let wind  = avg(idxs.map { hourly.windSpeed10m[$0] })
        var pm = 0.0
        if let air {
            let vals: [Double] = idxs.compactMap { i in
                guard i < hourly.time.count,
                      let j = air.hourly.time.firstIndex(of: hourly.time[i]) else { return nil }
                return air.hourly.pm25[j]
            }
            pm = avg(vals)
        }
        
        func ymd(_ s: String) -> DateComponents {
            let p = s.split(separator: "-").compactMap { Int($0) }
            return DateComponents(year: p[0], month: p[1], day: p[2])
        }
        var sc = ymd(eStr); sc.hour = 19; let nStart = cal.date(from: sc) ?? now
        var ec = ymd(eStr); ec.day! += 1; ec.hour = 5; let nEnd = cal.date(from: ec) ?? now
        var mc = ymd(eStr); mc.hour = 24; let nMid = cal.date(from: mc) ?? now
        
        let moonMid = MoonCalculator.illumination(date: nMid)
        let exposure = MoonCalculator.nightExposure(start: nStart, end: nEnd, lat: lat, lng: lng)
        let score = ScoreCalculator.compute(NightInputs(
            cloud: cloud, humidity: hum, pm25: pm, wind: wind,
            moonIllum: moonMid.fraction, moonExposure: exposure))
        
        func classify(_ code: Int, _ c: Double) -> SkyCondition {
            if code >= 95 { return .rain }
            if (71...77).contains(code) || code == 85 || code == 86 { return .snow }
            if (51...67).contains(code) || (80...82).contains(code) { return .rain }
            if code == 45 || code == 48 { return .fog }
            if c < 15 { return .clear }; if c < 50 { return .partly }
            if c < 85 { return .cloudy }; return .overcast
        }
        let repIdx = idxs.first { hourly.time[$0].hasSuffix("T23:00") } ?? idxs.first ?? -1
        let condition = classify(repIdx >= 0 ? hourly.weatherCode[repIdx] : cur.weatherCode, cloud)
        
        let moonNow = MoonCalculator.illumination(date: now)
        let moonPos = MoonCalculator.position(date: now, lat: lat, lng: lng)
        
        let sunNow = MoonCalculator.getSunAltitude(date: now, lat: lat, lng: lng)
        let sunLater = MoonCalculator.getSunAltitude(date: now.addingTimeInterval(600), lat: lat, lng: lng)
        let tw = 0.12
        let daypart: Daypart = sunNow > tw ? .day : sunNow < -tw ? .night : (sunLater > sunNow ? .dawn : .dusk)
        
        func parseDate(_ s: String) -> Date {
            let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = .current; f.dateFormat = "yyyy-MM-dd'T'HH:mm"
            return f.date(from: s) ?? now
        }
        let moonRefDate: Date
        if cal.component(.hour, from: now) < 6 {
            moonRefDate = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: now))!
        } else {
            moonRefDate = cal.startOfDay(for: now)
        }
        let moonRS = MoonCalculator.moonRiseSet(referenceDate: moonRefDate, lat: lat, lng: lng)

        return StargazingEntry(
            date: now, score: score, locationName: name,
            condition: condition, daypart: daypart,
            moonIllum: moonNow.fraction, moonPhase: moonNow.phase, moonAltitude: moonPos.altitude,
            temperature: cur.temperature2m, pressure: cur.surfacePressure,
            nightCloud: cloud, nightHumidity: hum, nightWind: wind, nightPm25: pm,
            sunrise: parseDate(wx.daily.sunrise.first ?? ""),
            sunset: parseDate(wx.daily.sunset.first ?? ""),
            moonName: ScoreCalculator.moonPhaseName(phase: moonNow.phase),
            moonrise: moonRS.rise,
            moonset:  moonRS.set)
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
        .description("오늘 밤 관측 지수")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
