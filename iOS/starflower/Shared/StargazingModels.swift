//
//  StargazingModels.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import Foundation

struct SavedLocation: Codable, Equatable {
    var name: String
    var admin1: String?
    var country: String?
    var latitude: Double
    var longitude: Double
}

struct GeoResult: Identifiable {
    let id: Int
    let name: String
    let admin1: String?
    let country: String?
    let latitude: Double
    let longitude: Double

    var displayName: String {
        [admin1, country].compactMap { $0 }.joined(separator: ", ")
    }
}

struct NightInputs {
    var cloud: Double
    var humidity: Double
    var pm25: Double
    var wind: Double
    var moonIllum: Double
    var moonExposure: Double
}

struct DayForecast: Identifiable {
    let id = UUID()
    var date: Date
    var label: String
    var score: Int
    var condition: SkyCondition
}

struct StargazingData {
    var location: SavedLocation
    var score: Int
    var condition: SkyCondition
    var daypart: Daypart
    var temperature: Double
    var pressure: Double
    var nightCloud: Double
    var nightHumidity: Double
    var nightWind: Double
    var nightPm25: Double
    var sunrise: Date
    var sunset: Date
    var moonIllum: Double
    var moonPhase: Double
    var moonAltitude: Double
    var moonName: String
    var moonrise: Date?
    var moonset: Date?
    var forecast: [DayForecast]
    var updatedAt: Date
}
