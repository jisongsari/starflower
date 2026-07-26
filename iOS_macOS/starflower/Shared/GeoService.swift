//
//  GeoService.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import Foundation
import MapKit

final class GeoService {
    static let shared = GeoService()
    private init() {}

    // 생활 POI 제외 필터: 음식점·카페·미용실·생활체육시설 등은 걸러내고
    // 랜드마크(타워·테마파크·박물관·공원·천문대 등)는 통과시킨다.
    // '유명한 것 우선'은 MapKit 자동완성 랭킹이 담당.
    fileprivate static let poiFilter = MKPointOfInterestFilter(excluding: [
        // 생활 편의·금융·행정
        .atm, .bank, .mailbox, .postOffice, .police, .fireStation, .restroom,
        // 음식·주류
        .bakery, .brewery, .cafe, .distillery, .foodMarket, .restaurant,
        .winery, .nightlife,
        // 상점·서비스
        .store, .beauty, .spa, .laundry, .animalService,
        // 교통·차량
        .carRental, .automotiveRepair, .evCharger, .gasStation, .parking,
        .publicTransport,
        // 의료·교육
        .hospital, .pharmacy, .school, .university, .library,
        // 숙박·생활체육·오락
        .hotel, .fitnessCenter, .movieTheater,
        .bowling, .goKart, .miniGolf, .skatePark, .skating,
        .baseball, .basketball, .tennis, .volleyball,
        .swimming, .golf,
    ])

    // 이스터에그: 학교 카테고리는 제외 대상이지만 경기과학고만 예외 통과
    private let easterEggTriggers = ["경기과학고등학교", "경기과학", "경기과고", "경곽", "송죽학", "펑죽", "SRC", "학술정보관", "우정1관", "우정2관", "아름관", "창조관", "학습관"]
    private let easterEggQuery = "경기과학고등학교"

    func search(query: String) async -> [GeoResult] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return [] }

        // 이스터에그 검색은 일반 검색과 병렬로
        let normalized = q.replacingOccurrences(of: " ", with: "")
        let isEasterEgg = easterEggTriggers.contains {
            normalized.localizedCaseInsensitiveContains($0)
        }
        async let egg: GeoResult? = isEasterEgg ? searchEasterEgg() : nil

        // 1) 자동완성 후보 (지명 + 랜드마크 POI)
        let completions = (try? await SearchCompleter.complete(q)) ?? []

        // 2) 상위 후보만 좌표 해석 (후보당 검색 1회이므로 8개로 제한, 병렬)
        let top = Array(completions.prefix(8))
        let resolved: [GeoResult] = await withTaskGroup(of: (Int, GeoResult?).self) { group in
            for (idx, c) in top.enumerated() {
                group.addTask { [self] in (idx, await resolve(completion: c)) }
            }
            var slots = [GeoResult?](repeating: nil, count: top.count)
            for await (idx, r) in group { slots[idx] = r }
            return slots.compactMap { $0 }   // Apple 랭킹 순서 유지
        }

        // 3) 이스터에그를 최상단에 + 중복 제거 + 6개 제한
        var merged = resolved
        if let eggResult = await egg {
            merged.insert(eggResult, at: 0)
        }
        var seen = Set<String>()
        var out: [GeoResult] = []
        for r in merged {
            let key = "\(r.name)|\(r.admin1 ?? "")|\(r.country ?? "")"
            if seen.contains(key) { continue }
            seen.insert(key)
            out.append(r)
            if out.count >= 6 { break }
        }
        return out
    }

    // ── 완성 후보 → GeoResult ─────────────────────────────
    private func resolve(completion: MKLocalSearchCompletion) async -> GeoResult? {
        let search = MKLocalSearch(request: MKLocalSearch.Request(completion: completion))
        guard let item = try? await search.start().mapItems.first else { return nil }
        return makeResult(from: item, fallbackName: completion.title)
    }

    // ── 이스터에그: POI 필터 없이 직접 검색 ───────────────
    private func searchEasterEgg() async -> GeoResult? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = easterEggQuery
        request.resultTypes = .pointOfInterest
        // pointOfInterestFilter 미지정 = 전 카테고리 허용 (school 포함)
        guard let items = try? await MKLocalSearch(request: request).start().mapItems
        else { return nil }
        guard let item = items.first(where: { ($0.name ?? "").contains("경기과학고") })
        else { return nil }
        return makeResult(from: item, fallbackName: easterEggQuery, isPOI: true)
    }

    // ── MKMapItem → GeoResult 공통 변환 ───────────────────
    private func makeResult(from item: MKMapItem,
                            fallbackName: String,
                            isPOI: Bool = false) -> GeoResult? {
        let pm = item.placemark
        let poi = isPOI || item.pointOfInterestCategory != nil

        // 지명 결과는 도로·번지 단위 주소 제외.
        // POI 는 소재지 도로명을 갖는 게 정상이므로 이 가드를 우회한다.
        if !poi {
            guard pm.thoroughfare == nil, pm.subThoroughfare == nil else { return nil }
        }

        let coord = pm.coordinate
        guard CLLocationCoordinate2DIsValid(coord) else { return nil }

        let name = item.name
            ?? pm.name
            ?? fallbackName.components(separatedBy: ",").first?
                .trimmingCharacters(in: .whitespaces)
            ?? fallbackName

        // 행정 위계 사다리 (좁은 단위 → 넓은 단위, nil·중복 제거)
        // 예: 역곡동 → [역곡동, 부천시, 경기도] / 남산타워 → [용산동2가, 서울특별시]
        var ladder: [String] = []
        for step in [pm.subLocality, pm.locality, pm.subAdministrativeArea, pm.administrativeArea] {
            if let s = step, !s.isEmpty, !ladder.contains(s) { ladder.append(s) }
        }

        // 상위 지명: 지명은 사다리에서 자기 바로 위 단계,
        // POI 는 사다리의 가장 좁은 단계 (자신은 사다리에 없으므로)
        let admin1: String?
        if let idx = ladder.firstIndex(of: name), idx + 1 < ladder.count {
            admin1 = ladder[idx + 1]
        } else {
            admin1 = ladder.first { $0 != name }
        }

        // 세션 내 리스트 식별용 ID (이름+좌표 기반)
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(Int(coord.latitude * 1000))
        hasher.combine(Int(coord.longitude * 1000))

        return GeoResult(id: hasher.finalize(),
                         name: name,
                         admin1: admin1,
                         country: pm.country,
                         latitude: coord.latitude,
                         longitude: coord.longitude)
    }
}

// ── MKLocalSearchCompleter 일회성 래퍼 ────────────────────
// (델리게이트 기반 API 를 async 한 번 호출로 감싼다. 검색마다 새 인스턴스)
@MainActor
private final class SearchCompleter: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()
    private var continuation: CheckedContinuation<[MKLocalSearchCompletion], Error>?

    static func complete(_ fragment: String) async throws -> [MKLocalSearchCompletion] {
        try await SearchCompleter().run(fragment)
    }

    private func run(_ fragment: String) async throws -> [MKLocalSearchCompletion] {
        try await withCheckedThrowingContinuation { cont in
            continuation = cont
            completer.delegate = self
            completer.resultTypes = [.address, .pointOfInterest]   // 지명 + 랜드마크
            completer.pointOfInterestFilter = GeoService.poiFilter
            completer.queryFragment = fragment
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        continuation?.resume(returning: completer.results)
        continuation = nil
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

enum GeoError: Error { case httpError }
