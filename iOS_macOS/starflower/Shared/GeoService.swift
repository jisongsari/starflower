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

    // 행정 접미사 (긴 것부터 검사해야 '광역시'가 '시'보다 먼저 떨어진다)
    private let adminSuffixes = [
        "특별자치시","특별자치도","광역시","특별시","도",
        "시","군","구","동","읍","면","리","가"
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

        // Photon: 자동완성형 접두 일치 (위치 편향 없음 — 편향은 시골 소지명을
        //         밀어올리는 역효과가 있어 제거. 한글 매칭 자체가 국내 한정이라 불필요)
        // Open-Meteo: 한글 외국 지명 + 접미사 변형으로 동·리 단위 보강
        async let ph = searchPhoton(q)
        async let om = searchOpenMeteoExpanded(q)
        let phResults = (try? await ph) ?? []
        let omResults = (try? await om) ?? []
        return merge(query: q, lists: [phResults, omResults])
    }

    // ── 병합·랭킹 ─────────────────────────────────────────
    private func merge(query: String, lists: [[GeoResult]]) -> [GeoResult] {
        // 1) 키 기준 1차 중복 제거 (입력 순서 유지)
        var seen = Set<String>()
        var deduped: [GeoResult] = []
        for r in lists.flatMap({ $0 }) {
            let key = "\(r.name)|\(r.admin1 ?? "")|\(r.country ?? "")"
            if seen.contains(key) { continue }
            seen.insert(key)
            deduped.append(r)
        }

        // 2) (명칭 일치도 → 행정 단위 크기 → 원래 순서) 로 정렬
        //    예: '역곡' 검색 시 역곡동(가중치 3)이 역곡리(1)보다 위
        let sorted = deduped.enumerated()
            .sorted { a, b in
                let sa = matchScore(a.element.name, query: query)
                let sb = matchScore(b.element.name, query: query)
                if sa != sb { return sa > sb }
                let wa = levelWeight(a.element.name)
                let wb = levelWeight(b.element.name)
                if wa != wb { return wa > wb }
                return a.offset < b.offset
            }
            .map { $0.element }

        // 3) 접미사 제거 후 이름이 같고 좌표가 근접한 항목 제거
        var out: [GeoResult] = []
        for r in sorted {
            let n = stripAdminSuffix(r.name)
            let isDup = out.contains {
                stripAdminSuffix($0.name) == n &&
                abs($0.latitude - r.latitude) < 0.25 &&
                abs($0.longitude - r.longitude) < 0.25
            }
            if isDup { continue }
            out.append(r)
            if out.count >= 6 { break }
        }
        return out
    }

    /// 3: 정확 일치(접미사 무시), 2: 접두 일치, 1: 포함, 0: 무관
    private func matchScore(_ name: String, query: String) -> Int {
        if name == query { return 3 }
        let n = stripAdminSuffix(name)
        let qn = stripAdminSuffix(query)
        if n == qn { return 3 }
        if name.hasPrefix(query) || n.hasPrefix(qn) { return 2 }
        if name.contains(query) { return 1 }
        return 0
    }

    /// 행정 단위 크기 가중치 (동점 정렬용)
    private func levelWeight(_ name: String) -> Int {
        for suf in ["특별자치도"] where name.hasSuffix(suf) { return 8 }
        for suf in ["특별자치시","광역시","특별시"] where name.hasSuffix(suf) { return 7 }
        if name.hasSuffix("도") { return 8 }
        if name.hasSuffix("시") { return 6 }
        if name.hasSuffix("군") { return 5 }
        if name.hasSuffix("구") { return 4 }
        if name.hasSuffix("동") || name.hasSuffix("읍") { return 3 }
        if name.hasSuffix("면") { return 2 }
        if name.hasSuffix("리") || name.hasSuffix("가") { return 1 }
        return 4   // 접미사 없음(외국 도시 등)은 중간
    }

    private func stripAdminSuffix(_ s: String) -> String {
        for suf in adminSuffixes where s.count > suf.count && s.hasSuffix(suf) {
            return String(s.dropLast(suf.count))
        }
        return s
    }

    /// 결과 자체가 시 미만(구·동·읍·면·리) 등급인지 판별.
    /// 시 미만이면 상위 지명으로 시(city), 시·군이면 도(state)를 쓴다.
    private func isSubCity(name: String, type: String, osmValue: String) -> Bool {
        // Photon 타입이 도시 이상이라고 말하면 그대로 신뢰
        // ('대구'처럼 이름이 우연히 '구'로 끝나는 도시를 접미사 규칙에서 보호)
        if ["city", "state", "county", "country"].contains(type) { return false }
        if isKorean(name) {
            for suf in ["특별자치시","특별자치도","광역시","특별시"]
                where name.hasSuffix(suf) { return false }
            if name.hasSuffix("시") || name.hasSuffix("군") || name.hasSuffix("도") {
                return false
            }
            for suf in ["구","동","읍","면","리","가"] where name.hasSuffix(suf) {
                return true
            }
        }
        return ["district","locality","other"].contains(type)
            || ["suburb","neighbourhood","quarter","borough",
                "village","hamlet","city_district","district"].contains(osmValue)
    }

    // ── Photon ────────────────────────────────────────────
    private func searchPhoton(_ q: String) async throws -> [GeoResult] {
        var c = URLComponents(string: "https://photon.komoot.io/api/")!
        c.queryItems = [
            .init(name: "q", value: q),
            .init(name: "limit", value: "10"),
            .init(name: "lang", value: isKorean(q) ? "default" : "en"),
        ]

        var req = URLRequest(url: c.url!)
        req.setValue("Starflower/1.0 (stargazing app)", forHTTPHeaderField: "User-Agent")

        let (data, resp) = try await session.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw GeoError.httpError }
        let r = try JSONDecoder().decode(PhotonResponse.self, from: data)

        var out: [GeoResult] = []
        for f in r.features {
            let p = f.properties
            let key = p.osmKey ?? ""
            let type = p.type ?? ""
            guard key == "place" || key == "boundary" else { continue }
            guard type != "street", type != "house" else { continue }
            guard f.geometry.coordinates.count >= 2, let name = p.name, !name.isEmpty
            else { continue }
            let lon = f.geometry.coordinates[0]
            let lat = f.geometry.coordinates[1]

            // 상위 지명: 시 미만 등급이면 시(city) 우선, 시·군 등급이면 도(state)
            let admin1: String?
            if isSubCity(name: name, type: type, osmValue: p.osmValue ?? "") {
                admin1 = p.city ?? p.district ?? p.county ?? p.state
            } else {
                admin1 = p.state ?? p.county
            }

            out.append(GeoResult(id: p.osmId ?? (name.hashValue & 0x7FFFFFFF),
                                 name: name,
                                 admin1: admin1,
                                 country: p.country,
                                 latitude: lat, longitude: lon))
        }
        return out
    }

    // ── Open-Meteo ────────────────────────────────────────
    /// 접미사 없는 한글 검색어는 행정 접미사 변형을 함께 병렬 조회.
    /// ('역곡' → '역곡동', '역곡리' 등 동·리 단위까지 직접 커버)
    private func searchOpenMeteoExpanded(_ q: String) async throws -> [GeoResult] {
        var queries = [q]
        if isKorean(q), stripAdminSuffix(q) == q {
            queries += ["시", "군", "구", "동", "읍", "면", "리", "도"].map { q + $0 }
        }
        return await withTaskGroup(of: (Int, [GeoResult]).self) { group in
            for (idx, query) in queries.enumerated() {
                group.addTask { [self] in
                    (idx, (try? await searchOpenMeteo(query)) ?? [])
                }
            }
            var buckets = [[GeoResult]](repeating: [], count: queries.count)
            for await (idx, r) in group { buckets[idx] = r }
            return buckets.flatMap { $0 }
        }
    }

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
        return r.results?.map { item in
            // 상위 지명: 시 미만 등급이면 admin2(시·군) 우선, 아니면 admin1(도)
            let admin1: String?
            if isSubCity(name: item.name, type: "", osmValue: "") {
                admin1 = item.admin2 ?? item.admin1
            } else {
                admin1 = item.admin1
            }
            return GeoResult(id: item.id, name: item.name, admin1: admin1,
                             country: item.country,
                             latitude: item.latitude, longitude: item.longitude)
        } ?? []
    }
}

// ── 응답 구조 ─────────────────────────────────────────────
private struct PhotonResponse: Decodable { let features: [PhotonFeature] }
private struct PhotonFeature: Decodable {
    let geometry: PhotonGeometry
    let properties: PhotonProps
}
private struct PhotonGeometry: Decodable { let coordinates: [Double] }  // [lon, lat]
private struct PhotonProps: Decodable {
    let osmId: Int?
    let name: String?
    let country: String?
    let state: String?
    let county: String?
    let city: String?
    let district: String?
    let osmKey: String?
    let osmValue: String?
    let type: String?
    enum CodingKeys: String, CodingKey {
        case osmId = "osm_id"
        case name, country, state, county, city, district, type
        case osmKey = "osm_key"
        case osmValue = "osm_value"
    }
}
private struct OpenMeteoGeoResponse: Decodable { let results: [OpenMeteoGeoItem]? }
private struct OpenMeteoGeoItem: Decodable {
    let id: Int; let name: String; let latitude: Double; let longitude: Double
    let country: String?; let admin1: String?; let admin2: String?
}
enum GeoError: Error { case httpError }
