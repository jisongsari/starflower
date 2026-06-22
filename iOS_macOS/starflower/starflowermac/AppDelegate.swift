//
//  AppDelegate.swift
//  starflower
//
//  Created by 양지성 on 6/22/26.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    // 시작 시 메뉴바 전용(.accessory): Dock 아이콘 숨김
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

enum DockPolicy {
    // 메인 윈도우가 열릴 때 Dock 표시
    static func showDock() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    // 메인 윈도우가 닫힐 때 Dock 숨김
    static func hideDock() {
        NSApp.setActivationPolicy(.accessory)
    }
}
