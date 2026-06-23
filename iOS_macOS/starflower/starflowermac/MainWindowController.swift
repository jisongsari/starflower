//
//  MainWindowController.swift
//  starflower
//
//  Created by 양지성 on 6/23/26.
//


import AppKit
import SwiftUI

final class MainWindowController: NSObject, NSWindowDelegate {
    static let shared = MainWindowController()
    private var window: NSWindow?

    func show(vm: MacViewModel) {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            DockPolicy.showDock()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let host = NSHostingController(rootView: MacContentView(vm: vm))
        let w = NSWindow(contentViewController: host)
        w.title = "별바라기"
        w.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isMovableByWindowBackground = true
        w.setContentSize(NSSize(width: 800, height: 900))
        w.contentMinSize = NSSize(width: 500, height: 650)
        w.center()
        w.delegate = self
        w.isReleasedWhenClosed = false   // 닫아도 파괴 안 함
        w.identifier = NSUserInterfaceItemIdentifier("main")

        self.window = w
        w.makeKeyAndOrderFront(nil)
        DockPolicy.showDock()
        NSApp.activate(ignoringOtherApps: true)
    }

    // 닫기 → 숨김 + Dock 끔 (파괴 안 함)
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        DockPolicy.hideDock()
        return false
    }
}
