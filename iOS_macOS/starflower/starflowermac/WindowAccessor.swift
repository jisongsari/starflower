//
//  WindowAccessor.swift
//  starflower
//
//  Created by 양지성 on 6/22/26.
//

import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            guard let window = v.window else { return }
            DockPolicy.showDock()  // 윈도우 등장 → Dock 표시
            // 닫힘 감지
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window, queue: .main
            ) { _ in
                DockPolicy.hideDock()  // 윈도우 닫힘 → Dock 숨김
            }
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
