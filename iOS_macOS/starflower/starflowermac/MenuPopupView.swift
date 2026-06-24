//
//  MenuPopupView.swift
//  starflower
//
//  Created by 양지성 on 6/22/26.
//


import SwiftUI
import AppKit

struct MenuPopupView: View {
    @ObservedObject var vm: MacViewModel
    let openApp: () -> Void
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 0) {
            if let d = vm.data {
                Button {
                    openApp()
                } label: {
                    MacWidgetView(data: d)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(hovering ? 0.08 : 0))
                        )
                        //.scaleEffect(hovering ? 1.015 : 1)
                        .animation(.easeOut(duration: 0.15), value: hovering)
                }
                .buttonStyle(.plain)
                .onHover { hovering = $0 }
                .padding(6)
            } else {
                VStack(spacing: 10) {
                    if vm.isLoading { ProgressView().controlSize(.small) }
                    else { Text("위치를 설정해 주세요").font(.callout).foregroundStyle(.secondary) }
                }
                .frame(height: 150).frame(maxWidth: .infinity)
            }

            Divider()

            HStack {
                Button {
                    Task { await vm.loadData() }
                } label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(HoverIconButtonStyle())

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: { Label("종료", systemImage: "power") }
                .buttonStyle(HoverIconButtonStyle())
            }
            .padding(8)
        }
        .frame(width: 360)
        .onAppear {
            Task { await vm.loadData() }
        }
    }
}

struct HoverIconButtonStyle: ButtonStyle {
    @State private var hovering = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(hovering ? 0.08 : 0))
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.15), value: hovering)
    }
}
