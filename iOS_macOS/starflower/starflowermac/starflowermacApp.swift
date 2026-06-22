//
//  starflowermacApp.swift
//  starflowermac
//
//  Created by 양지성 on 6/22/26.
//

import SwiftUI

@main
struct starflowermacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var vm = MacViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        // 메뉴바 아이콘 + 팝업
        MenuBarExtra {
            MenuPopupView(vm: vm) {
                openWindow(id: "main")
            }
        } label: {
            Image(systemName: "moon.stars.fill")
        }
        .menuBarExtraStyle(.window)

        // 메인 윈도우 (정사각형)
        Window("별바라기", id: "main") {
            MacContentView(vm: vm)
                .frame(width: 480, height: 480)
                .background(WindowAccessor())  // 닫힘 감지
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
