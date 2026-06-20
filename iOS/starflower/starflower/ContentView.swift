//
//  ContentView.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = StargazingViewModel()

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
                    if vm.isLoading && vm.data == nil {
                        VStack(spacing: 14) {
                            ProgressView().tint(.white).scaleEffect(1.4)
                            Text("하늘을 살펴보는 중…").font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }.padding(.top, 180)
                    } else if let err = vm.errorMessage, vm.data == nil {
                        VStack(spacing: 12) {
                            Text(err).foregroundStyle(.white.opacity(0.7))
                            Button("다시 시도") { Task { await vm.loadData() } }
                                .buttonStyle(.bordered).tint(.white)
                        }.padding(.top, 180)
                    } else if let d = vm.data {
                        ScoreHeroView(score: d.score, condition: d.condition, temperature: d.temperature)
                        ForecastView(forecast: d.forecast)
                            .background {
                                        ZStack {
                                            Color.black
                                                .opacity(0.3)
                                                .blendMode(.softLight)
                                        }
                                    }
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.white.opacity(0.08), lineWidth: 1))
                        DetailGridView(data: d)
                        Text(footer(d)).font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.top, 6).padding(.bottom, 40)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 100)
            }

            VStack {
                HStack {
                    Button { vm.showSearch = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill").font(.system(size: 13))
                            Text(vm.savedLocation?.name ?? "위치 선택")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold))
                        }.foregroundStyle(.white.opacity(0.95))
                    }
                    Spacer()
                    if vm.savedLocation != nil {
                        Button { Task { await vm.loadData() } } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(width: 34, height: 34)
                                .background(.white.opacity(0.1)).clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.top, 56)
                Spacer()
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .sheet(isPresented: $vm.showSearch) {
            SearchView(onSelect: vm.selectLocation, dismissable: vm.savedLocation != nil)
                .presentationDetents([.large])
        }
        .task { await vm.loadData() }
    }

    private func footer(_ d: StargazingData) -> String {
        var s = d.location.name
        if let a = d.location.admin1 { s += " · \(a)" }
        return s + " · Open-Meteo · 경기과학고등학교"
    }
}
