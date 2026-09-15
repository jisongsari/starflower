//
//  MainWindowController.swift
//  starflower
//

import AppKit
import SwiftUI

@MainActor
final class MainWindowController: NSObject, NSWindowDelegate {
    static let shared = MainWindowController()
    private var window: NSWindow?

    func show(vm: MacViewModel) {
        Task { await vm.loadData() }

        let w = window ?? makeWindow()
        if w.contentViewController == nil {
            w.contentViewController = NSHostingController(rootView: MacContentView(vm: vm))
        }
        RenderGate.shared.isActive = true
        w.makeKeyAndOrderFront(nil)
        DockPolicy.showDock()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeWindow() -> NSWindow {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        w.title = "별바라기"
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isMovableByWindowBackground = true
        w.contentMinSize = NSSize(width: 500, height: 650)
        w.center()
        w.delegate = self
        w.isReleasedWhenClosed = false   // 닫아도 파괴 안 함
        w.identifier = NSUserInterfaceItemIdentifier("main")

        NotificationCenter.default.addObserver(
            self, selector: #selector(occlusionChanged),
            name: NSWindow.didChangeOcclusionStateNotification, object: w)

        window = w
        return w
    }

    /// 최소화되거나 다른 창에 완전히 가려지면 배경 애니메이션을 멈춘다.
    /// (macOS 27은 이걸 OS가 대신 해주지 않는다)
    @objc private func occlusionChanged() {
        guard let w = window else { return }
        RenderGate.shared.isActive = w.occlusionState.contains(.visible)
    }

    /// 닫기 → 숨김 + Dock 끔 + SwiftUI 뷰 트리 해제 (창 객체 자체는 유지)
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        RenderGate.shared.isActive = false
        sender.orderOut(nil)
        sender.contentViewController = nil
        sender.contentView = NSView()
        DockPolicy.hideDock()
        return false
    }
}
