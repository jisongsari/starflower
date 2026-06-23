//
//  AppDelegate.swift
//  starflower
//
//  Created by 양지성 on 6/22/26.
//

import AppKit
import SwiftUI
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        // 최초 실행 시 메인 창 표시
        DispatchQueue.main.async {
            MainWindowController.shared.show(vm: SharedVM.instance)
        }
    }
    // Dock 아이콘 클릭(앱 재오픈) 시 메인 창 표시
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MainWindowController.shared.show(vm: SharedVM.instance)
        return true
    }
}

// vm을 앱 전역에서 공유 (App 구조체와 동일 인스턴스 사용)
enum SharedVM {
    static let instance = MacViewModel()
}

enum DockPolicy {
    static func showDock() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    static func hideDock() {
        NSApp.setActivationPolicy(.accessory)
    }
}

enum LaunchAtLogin {
    static var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
            } catch { print("로그인 항목 설정 실패: \(error)") }
        }
    }
}
