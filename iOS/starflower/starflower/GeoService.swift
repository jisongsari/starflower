//
//  GeoService.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import Foundation

final class GeoService {
    static let shared = GeoService()
    private init() {}
    private let session = URLSession.shared

    private let placeTypes: Set<String> = [
        "city","town","village","hamlet","municipality",
        "suburb","neighbourhood","quarter","borough",
        "city_district","district","county","province",
        "state","region","administrative","island"
    ]

    private func isKorean(_ s: String) -> Bool {
        s.unicodeScalars.contains {
            ($0.value >= 0xAC00 && $0.value <= 0xD7A3) ||
            ($0.value >= 0x1100 && $0.value <= 0x11FF) ||
            ($0.value >= 0x3130 && $0.value <= 0x318F)
        }
    }

    func search(query: String) async -> [GeoResult] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return [] }
        if let r = try? await searchNominatim(q), !r.isEmpty { return r }
        return (try? await searchOpenMeteo(q)) ?? []
    }

    // ── Nominatim ─────────────────────────────────────────
    private func searchNominatim(_ q: String) async throws -> [GeoResult] {
        if isKorean(q) {
            async let kr  = nominatimFetch(q, countryCode: "kr")
            async let all = nominatimFetch(q, countryCode: nil)
            let (krItems, allItems) = await ((try? kr) ?? [], (try? all) ?? [])
            let krIds = Set(krItems.map { $0.placeId })
            let merged = krItems + allItems.filter { !krIds.contains($0.placeId) }
            return parseItems(merged)
        } else {
            return parseItems(try await nominatimFetch(q, countryCode: nil))
        }
    }

    private func nominatimFetch(_ q: String, countryCode: String?) async throws -> [NominatimItem] {
        var c = URLComponents(string: "https://nominatim.openstreetmap.org/search")!
        var items: [URLQueryItem] = [
            .init(name: "q", value: q),
            .init(name: "format", value: "jsonv2"),
            .init(name: "addressdetails", value: "1"),
            .init(name: "accept-language", value: "ko"),
            .init(name: "limit", value: "10"),
        ]
        if let cc = countryCode { items.append(.init(name: "countrycodes", value: cc)) }
        c.queryItems = items

        var req = URLRequest(url: c.url!)
        req.setValue("ko", forHTTPHeaderField: "Accept-Language")
        req.setValue("Starflower/1.0 (stargazing app)", forHTTPHeaderField: "User-Agent")

        let (data, resp) = try await session.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw GeoError.httpError }
        return try JSONDecoder().decode([NominatimItem].self, from: data)
    }

    private func parseItems(_ items: [NominatimItem]) -> [GeoResult] {
        let sorted = items.sorted { ($0.importance ?? 0) > ($1.importance ?? 0) }
        var seen = Set<String>()
        var out: [GeoResult] = []
        for it in sorted {
            let kind = it.addresstype ?? it.type ?? ""
            let isPlace = placeTypes.contains(kind)
                || it.category == "place" || it.category == "boundary"
            guard isPlace else { continue }
            guard let lat = Double(it.lat), let lon = Double(it.lon) else { continue }
            let a = it.address
            let name = it.name ?? a?.city ?? a?.town ?? a?.village
                ?? it.displayName.components(separatedBy: ",").first?
                    .trimmingCharacters(in: .whitespaces) ?? ""
            let admin1 = a?.state ?? a?.province
            let country = a?.country
            let key = "\(name)|\(admin1 ?? "")|\(country ?? "")"
            if seen.contains(key) { continue }
            seen.insert(key)
            out.append(GeoResult(id: it.placeId, name: name, admin1: admin1,
                                 country: country, latitude: lat, longitude: lon))
            if out.count >= 6 { break }
        }
        return out
    }

    // ── Open-Meteo 백업 ───────────────────────────────────
    private func searchOpenMeteo(_ q: String) async throws -> [GeoResult] {
        var c = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        c.queryItems = [
            .init(name: "name", value: q),
            .init(name: "count", value: "6"),
            .init(name: "language", value: "ko"),
            .init(name: "format", value: "json"),
        ]
        let (data, _) = try await session.data(from: c.url!)
        let r = try JSONDecoder().decode(OpenMeteoGeoResponse.self, from: data)
        return r.results?.map {
            GeoResult(id: $0.id, name: $0.name, admin1: $0.admin1,
                      country: $0.country, latitude: $0.latitude, longitude: $0.longitude)
        } ?? []
    }
}

private struct NominatimItem: Decodable {
    let placeId: Int
    let lat: String
    let lon: String
    let name: String?
    let displayName: String
    let addresstype: String?
    let type: String?
    let category: String?
    let importance: Double?
    let address: NominatimAddress?
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case lat, lon, name
        case displayName = "display_name"
        case addresstype, type, category, importance, address
    }
}
private struct NominatimAddress: Decodable {
    let city: String?; let town: String?; let village: String?
    let county: String?; let state: String?; let province: String?; let country: String?
}
private struct OpenMeteoGeoResponse: Decodable { let results: [OpenMeteoGeoItem]? }
private struct OpenMeteoGeoItem: Decodable {
    let id: Int; let name: String; let latitude: Double; let longitude: Double
    let country: String?; let admin1: String?
}
enum GeoError: Error { case httpError }
