//
//  starflowermacApp.swift
//  starflowermac
//
//  Created by 양지성 on 9/15/26.
//

import SwiftUI

@main
struct starflowermacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var vm = SharedVM.instance

    // 이 값이 false 가 되면 MenuBarExtra 가 메뉴 막대에서 즉시 사라진다.
    @AppStorage(MenuBarVisibility.key) private var showMenuBarExtra = true

    var body: some Scene {
        MenuBarExtra(isInserted: $showMenuBarExtra) {
            MenuPopupView(vm: vm) {
                MainWindowController.shared.show(vm: vm)
            }
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}
