//
//  StargazingViewModel.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import Foundation
import SwiftUI
import Combine
import WidgetKit

@MainActor
final class StargazingViewModel: ObservableObject {
    @Published var data: StargazingData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSearch = false
    @Published var savedLocation: SavedLocation? { didSet { persist() } }

    private let weather = WeatherService.shared
    private let appGroup = UserDefaults(suiteName: "group.com.songsari.starflower")
    private let key = "starflower.location.v1"

    private let weekdays = ["일","월","화","수","목","금","토"]
    private var cal: Calendar { Calendar.current }

    init() {
        if let d = appGroup?.data(forKey: key),
           let loc = try? JSONDecoder().decode(SavedLocation.self, from: d) {
            savedLocation = loc
        } else {
            showSearch = true
        }
    }

    func selectLocation(_ r: GeoResult) {
        savedLocation = SavedLocation(name: r.name, admin1: r.admin1, country: r.country,
                                      latitude: r.latitude, longitude: r.longitude)
        showSearch = false
        data = nil           // 이전 데이터 치워서 로딩창 표시
        Task { await loadData() }
    }

    func loadData() async {
        guard let loc = savedLocation else { return }
        isLoading = true; errorMessage = nil
        do {
            async let w = weather.fetchWeather(lat: loc.latitude, lng: loc.longitude)
            async let a = weather.fetchAir(lat: loc.latitude, lng: loc.longitude)
            let (wx, air) = try await (w, a)
            data = buildData(loc, wx, air)
            saveForWidget(loc)
        } catch {
            errorMessage = "날씨 정보를 불러오지 못했어요."
        }
        isLoading = false
    }

    private func persist() {
        guard let loc = savedLocation, let e = try? JSONEncoder().encode(loc) else { return }
        appGroup?.set(e, forKey: key)
    }
    private func saveForWidget(_ loc: SavedLocation) {
        appGroup?.set(loc.latitude, forKey: "latitude")
        appGroup?.set(loc.longitude, forKey: "longitude")
        appGroup?.set(loc.name, forKey: "locationName")
        WidgetCenter.shared.reloadAllTimelines()
    }

    // ── 데이터 조립 (웹 buildData 동일) ───────────────────
    private func buildData(_ loc: SavedLocation, _ wx: WeatherResponse, _ air: AirResponse?) -> StargazingData {
        let now = Date()
        let cur = wx.current
        let hourly = wx.hourly
        let lat = loc.latitude, lng = loc.longitude

        let hour = cal.component(.hour, from: now)
        let todayEvening = hour < 6 ? cal.date(byAdding: .day, value: -1, to: now)! : now

        var forecast: [DayForecast] = []
        var n0Cloud = cur.cloudCover, n0Hum = cur.relativeHumidity2m
        var n0Wind = cur.windSpeed10m, n0Pm = 0.0

        for i in 0..<3 {
            let evening = cal.date(byAdding: .day, value: i, to: todayEvening)!
            let eStr = dateStr(evening)
            let mStr = dateStr(cal.date(byAdding: .day, value: 1, to: evening)!)
            let idxs = nightIndices(hourly.time, eStr, mStr)

            let cloud = avg(idxs.map { hourly.cloudCover[$0] })
            let hum   = avg(idxs.map { hourly.relativeHumidity2m[$0] })
            let wind  = avg(idxs.map { hourly.windSpeed10m[$0] })
            let pm    = airAvg(air, hourly.time, idxs)
            if i == 0 { n0Cloud = cloud; n0Hum = hum; n0Wind = wind; n0Pm = pm }

            let moonMid = MoonCalculator.illumination(date: nightMidnight(eStr))
            let exposure = MoonCalculator.nightExposure(
                start: nightStart(eStr), end: nightEnd(eStr), lat: lat, lng: lng)

            let score = ScoreCalculator.compute(NightInputs(
                cloud: cloud, humidity: hum, pm25: pm, wind: wind,
                moonIllum: moonMid.fraction, moonExposure: exposure))

            let repIdx = idxs.first { hourly.time[$0].hasSuffix("T23:00") } ?? idxs.first ?? -1
            let repCode = repIdx >= 0 ? hourly.weatherCode[repIdx] : cur.weatherCode
            let cond = classifySky(repCode, cloud)

            let label = i == 0 ? "오늘" : weekdays[cal.component(.weekday, from: evening) - 1]
            forecast.append(DayForecast(date: evening, label: label, score: score, condition: cond))
        }

        let moonNow = MoonCalculator.illumination(date: now)
        let moonPos = MoonCalculator.position(date: now, lat: lat, lng: lng)
        let condition = forecast.first?.condition ?? classifySky(cur.weatherCode, cur.cloudCover)

        // 낮/밤/노을
        let sunNow = MoonCalculator.getSunAltitude(date: now, lat: lat, lng: lng)
        let sunLater = MoonCalculator.getSunAltitude(date: now.addingTimeInterval(600), lat: lat, lng: lng)
        let tw = 0.12
        let daypart: Daypart
        if sunNow > tw { daypart = .day }
        else if sunNow < -tw { daypart = .night }
        else { daypart = sunLater > sunNow ? .dawn : .dusk }
        
        // past_days=1 추가로 daily[0]=어제, [1]=오늘, [2]=내일
        let daily = wx.daily
        let todayIdx = 1  // 오늘은 항상 index 1
        let isEarly = hour < 6

        // 0~6시: 전일 일몰(daily[0]) + 금일 일출(daily[1])
        // 나머지: 금일 일몰(daily[1]) + 익일 일출(daily[2])
        let chosenSunset  = parseDate(daily.sunset[isEarly ? 0 : todayIdx])
        let chosenSunrise = parseDate(daily.sunrise[isEarly ? todayIdx : min(todayIdx + 1, daily.sunrise.count - 1)])

        // 0~6시엔 전일 기준, 나머지는 오늘 기준
        let moonRefDate: Date
        if hour < 6 {
            moonRefDate = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: now))!
        } else {
            moonRefDate = cal.startOfDay(for: now)
        }
        let moonRS = MoonCalculator.moonRiseSet(
            referenceDate: moonRefDate, lat: lat, lng: lng)
        
        return StargazingData(
            location: loc,
            score: forecast.first?.score ?? 0,
            condition: condition,
            daypart: daypart,
            temperature: cur.temperature2m,
            pressure: cur.surfacePressure,
            nightCloud: n0Cloud, nightHumidity: n0Hum, nightWind: n0Wind, nightPm25: n0Pm,
            sunrise: chosenSunrise,
            sunset: chosenSunset,
            moonIllum: moonNow.fraction, moonPhase: moonNow.phase,
            moonAltitude: moonPos.altitude,
            moonName: ScoreCalculator.moonPhaseName(phase: moonNow.phase),
            moonrise: moonRS.rise,
            moonset: moonRS.set,
            forecast: forecast,
            updatedAt: now)
    }

    // ── 유틸 ──────────────────────────────────────────────
    private func dateStr(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"; return f.string(from: d)
    }
    private func nightIndices(_ times: [String], _ e: String, _ m: String) -> [Int] {
        times.enumerated().compactMap { i, t in
            let d = String(t.prefix(10))
            guard let h = Int(t.dropFirst(11).prefix(2)) else { return nil }
            if d == e && h >= 19 { return i }
            if d == m && h <= 5  { return i }
            return nil
        }
    }
    private func ymd(_ s: String) -> DateComponents? {
        let p = s.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        return DateComponents(year: p[0], month: p[1], day: p[2])
    }
    private func nightStart(_ e: String) -> Date {
        var c = ymd(e)!; c.hour = 19; return cal.date(from: c) ?? Date()
    }
    private func nightMidnight(_ e: String) -> Date {
        var c = ymd(e)!; c.hour = 24; return cal.date(from: c) ?? Date()  // 다음날 00:00
    }
    private func nightEnd(_ e: String) -> Date {
        var c = ymd(e)!; c.day! += 1; c.hour = 5; return cal.date(from: c) ?? Date()
    }
    private func avg(_ v: [Double]) -> Double {
        let f = v.filter { $0.isFinite }
        return f.isEmpty ? 0 : f.reduce(0, +) / Double(f.count)
    }
    private func airAvg(_ air: AirResponse?, _ times: [String], _ idxs: [Int]) -> Double {
        guard let air else { return 0 }
        let vals: [Double] = idxs.compactMap { i in
            guard i < times.count, let j = air.hourly.time.firstIndex(of: times[i]) else { return nil }
            return air.hourly.pm25[j]
        }
        return avg(vals)
    }
    private func classifySky(_ code: Int, _ cloud: Double) -> SkyCondition {
        if code >= 95 { return .rain }
        if (71...77).contains(code) || code == 85 || code == 86 { return .snow }
        if (51...67).contains(code) || (80...82).contains(code) { return .rain }
        if code == 45 || code == 48 { return .fog }
        if cloud < 15 { return .clear }
        if cloud < 50 { return .partly }
        if cloud < 85 { return .cloudy }
        return .overcast
    }
    private func parseDate(_ s: String) -> Date {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return f.date(from: s) ?? Date()
    }
}
