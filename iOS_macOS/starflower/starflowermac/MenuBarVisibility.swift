//
//  MenuBarVisibility.swift
//  starflower
//
//  Created by 양지성 on 9/16/26.
//

import Foundation

/// 메뉴 막대 아이콘 표시 여부.
/// SwiftUI 쪽은 @AppStorage 로, AppKit 쪽은 이 타입으로 같은 키를 읽는다.
enum MenuBarVisibility {
    static let key = "showMenuBarExtra"

    /// 기본값 등록. 앱 시작 시 한 번 호출한다.
    /// 등록해두지 않으면 값이 없을 때 bool(forKey:) 가 false 를 돌려줘
    /// 첫 실행에 메뉴 막대가 안 뜬다.
    static func registerDefault() {
        UserDefaults.standard.register(defaults: [key: true])
    }

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: key)
    }
}
