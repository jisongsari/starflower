//
//  RecentSearchStore.swift
//  starflower
//
//  Created by 양지성 on 7/12/26.
//

import Foundation

enum RecentSearchStore {
    static func load(key: String) -> [GeoResult] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([GeoResult].self, from: data) else { return [] }
        return list
    }

    static func add(_ result: GeoResult, key: String) {
        var list = load(key: key)
        list.removeAll { $0.name == result.name && $0.admin1 == result.admin1 && $0.country == result.country }
        list.insert(result, at: 0)
        if list.count > 10 { list = Array(list.prefix(10)) }
        guard let data = try? JSONEncoder().encode(list) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func remove(_ result: GeoResult, key: String) {
        var list = load(key: key)
        list.removeAll { $0.name == result.name && $0.admin1 == result.admin1 && $0.country == result.country }
        guard let data = try? JSONEncoder().encode(list) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clear(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
