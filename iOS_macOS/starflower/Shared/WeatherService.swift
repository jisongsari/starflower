//
//  WeatherService.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import Foundation

// ── 응답 데이터 구조 ──────────────────────────────────────
struct WeatherResponse: Decodable {
    let current: CurrentWeather
    let hourly: HourlyWeather
    let daily: DailyWeather
}

struct CurrentWeather: Decodable {
    let time: String
    let temperature2m: Double
    let relativeHumidity2m: Double
    let cloudCover: Double
    let windSpeed10m: Double
    let surfacePressure: Double
    let weatherCode: Int
    let isDay: Int

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m        = "temperature_2m"
        case relativeHumidity2m   = "relative_humidity_2m"
        case cloudCover           = "cloud_cover"
        case windSpeed10m         = "wind_speed_10m"
        case surfacePressure      = "surface_pressure"
        case weatherCode          = "weather_code"
        case isDay                = "is_day"
    }
}

struct HourlyWeather: Decodable {
    let time: [String]
    let cloudCover: [Double]
    let relativeHumidity2m: [Double]
    let windSpeed10m: [Double]
    let temperature2m: [Double]
    let weatherCode: [Int]

    enum CodingKeys: String, CodingKey {
        case time
        case cloudCover           = "cloud_cover"
        case relativeHumidity2m   = "relative_humidity_2m"
        case windSpeed10m         = "wind_speed_10m"
        case temperature2m        = "temperature_2m"
        case weatherCode          = "weather_code"
    }
}

struct DailyWeather: Decodable {
    let time: [String]
    let sunrise: [String]
    let sunset: [String]
}

struct AirResponse: Decodable {
    let hourly: AirHourly
}

struct AirHourly: Decodable {
    let time: [String]
    let pm25: [Double?]

    enum CodingKeys: String, CodingKey {
        case time
        case pm25 = "pm2_5"
    }
}

// ── WeatherService ────────────────────────────────────────
final class WeatherService {

    static let shared = WeatherService()
    private init() {}

    private let session = URLSession.shared
    private let decoder = JSONDecoder()

    // 날씨 데이터 fetch
    func fetchWeather(lat: Double, lng: Double) async throws -> WeatherResponse {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude",       value: String(lat)),
            .init(name: "longitude",      value: String(lng)),
            .init(name: "current",        value: "temperature_2m,relative_humidity_2m,cloud_cover,wind_speed_10m,surface_pressure,weather_code,is_day"),
            .init(name: "hourly",         value: "cloud_cover,relative_humidity_2m,wind_speed_10m,temperature_2m,weather_code"),
            .init(name: "daily",          value: "sunrise,sunset"),
            .init(name: "wind_speed_unit",value: "ms"),
            .init(name: "timezone",       value: "auto"),
            .init(name: "forecast_days",  value: "4"),
            .init(name: "past_days", value: "1"),
        ]

        let (data, response) = try await session.data(from: components.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw ServiceError.httpError
        }
        return try decoder.decode(WeatherResponse.self, from: data)
    }

    // 대기질(PM2.5) fetch — 실패해도 앱 진행 (nil 반환)
    func fetchAir(lat: Double, lng: Double) async -> AirResponse? {
        var components = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!
        components.queryItems = [
            .init(name: "latitude",      value: String(lat)),
            .init(name: "longitude",     value: String(lng)),
            .init(name: "hourly",        value: "pm2_5"),
            .init(name: "timezone",      value: "auto"),
            .init(name: "forecast_days", value: "4"),
        ]

        guard let url = components.url,
              let (data, _) = try? await session.data(from: url),
              let result = try? decoder.decode(AirResponse.self, from: data)
        else { return nil }

        return result
    }
}

// ── 에러 타입 ─────────────────────────────────────────────
enum ServiceError: Error, LocalizedError {
    case httpError
    case noData

    var errorDescription: String? {
        switch self {
        case .httpError: return "날씨 정보를 불러오지 못했어요."
        case .noData:    return "데이터가 없어요."
        }
    }
}
