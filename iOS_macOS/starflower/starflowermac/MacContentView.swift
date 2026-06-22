//
//  MacContentView.swift
//  starflower
//
//  Created by 양지성 on 6/22/26.
//


import SwiftUI

struct MacContentView: View {
    @ObservedObject var vm: MacViewModel
    @State private var showSearch = false

    var body: some View {
        ZStack {
            if let d = vm.data {
                SkyBackgroundView(condition: d.condition, daypart: d.daypart,
                                  moonIllum: d.moonIllum, moonPhase: d.moonPhase,
                                  moonAltitude: d.moonAltitude)
            } else {
                SkyBackgroundView(condition: .clear, daypart: .night,
                                  moonIllum: 0.5, moonPhase: 0.25, moonAltitude: 0.5)
            }

            ScrollView {
                VStack(spacing: 16) {
                    if let d = vm.data {
                        ScoreHeroView(score: d.score, condition: d.condition, temperature: d.temperature)
                        ForecastView(forecast: d.forecast)
                            .background(Color.black.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.white.opacity(0.08), lineWidth: 1))
                        DetailGridView(data: d)
                    } else if vm.isLoading {
                        ProgressView().tint(.white).scaleEffect(1.3).padding(.top, 160)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 56)
                .padding(.bottom, 24)
            }

            // 상단 바
            VStack {
                HStack {
                    Button { showSearch = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill").font(.system(size: 12))
                            Text(vm.savedLocation?.name ?? "위치 선택")
                                .font(.system(size: 15, weight: .semibold))
                            Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold))
                        }.foregroundStyle(.white.opacity(0.95))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    if vm.savedLocation != nil {
                        Button { Task { await vm.loadData() } } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(width: 30, height: 30)
                                .background(.white.opacity(0.1)).clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18).padding(.top, 14)
                Spacer()
            }
        }
        .frame(width: 480, height: 480)
        .preferredColorScheme(.dark)
        .task { await vm.loadData() }
        .sheet(isPresented: $showSearch) {
            MacSearchView(onSelect: { vm.selectLocation($0); showSearch = false },
                          onCancel: { showSearch = false })
        }
    }
}
