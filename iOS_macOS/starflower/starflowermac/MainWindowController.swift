//
//  MainWindowController.swift
//  starflower
//
//  Created by 양지성 on 9/15/26.
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
            // contentViewController 를 붙이면 AppKit 이 그 뷰의 fittingSize 로
            // 창을 다시 맞춘다. 닫을 때 뷰 트리를 해제하므로 재오픈 때마다
            // 이 리사이즈가 걸려 크기가 리셋된다. 대입 전후로 프레임을 보존한다.
            let frame = w.frame
            w.contentViewController = NSHostingController(rootView: MacContentView(vm: vm))
            w.setFrame(frame, display: false)
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
        w.delegate = self
        w.isReleasedWhenClosed = false
        w.identifier = NSUserInterfaceItemIdentifier("main")

        // 마지막으로 열렸던 데스크탑으로 끌고 가지 말고, 지금 보고 있는 데스크탑에서 열리게 한다.
        w.collectionBehavior = [.moveToActiveSpace, .fullScreenPrimary]

        // 실행 간 크기·위치 유지. 저장된 프레임이 없을 때만 가운데 정렬.
        w.setFrameAutosaveName("main")
        if !w.setFrameUsingName("main") { w.center() }

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

    /// 메뉴 막대 아이콘이 꺼져 있으면 창을 닫는 것 = 앱 종료.
    /// 켜져 있으면 숨김 + Dock 끔 + SwiftUI 뷰 트리 해제 (창 객체·프레임은 유지).
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard MenuBarVisibility.isEnabled else {
            NSApp.terminate(nil)
            return false
        }
        RenderGate.shared.isActive = false
        sender.orderOut(nil)
        sender.contentViewController = nil
        sender.contentView = NSView()
        DockPolicy.hideDock()
        return false
    }
}
