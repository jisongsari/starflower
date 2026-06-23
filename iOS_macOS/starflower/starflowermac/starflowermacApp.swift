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
    @StateObject private var vm = SharedVM.instance

    var body: some Scene {
        MenuBarExtra {
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
