//
//  MenuPopupView.swift
//  starflower
//
//  Created by 양지성 on 6/22/26.
//


import SwiftUI

struct MenuPopupView: View {
    @ObservedObject var vm: MacViewModel
    let openApp: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let d = vm.data {
                MacWidgetView(data: d)
                    .padding(14)
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
                .buttonStyle(.borderless)

                Spacer()

                Button("앱 열기") { openApp() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(12)
        }
        .frame(width: 360)
        .task { if vm.data == nil { await vm.loadData() } }
    }
}