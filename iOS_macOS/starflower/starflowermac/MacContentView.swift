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
    @State private var showSettings = false
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        ZStack {
            if let d = vm.data {
                SkyBackgroundView(condition: d.condition, daypart: d.daypart,
                                  moonIllum: d.moonIllum, moonPhase: d.moonPhase,
                                  moonAltitude: d.moonAltitude,
                                  cloudCover: d.nightCloud)
            } else {
                SkyBackgroundView(condition: .clear, daypart: .night,
                                  moonIllum: 0.5, moonPhase: 0.25, moonAltitude: 0.5, cloudCover: 0)
            }

            ScrollView {
                VStack(spacing: 16) {
                    if let d = vm.data {
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
                            .padding(.top, -3)

                        Text(footer(d))
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.top, 6)
                            .padding(.bottom, 8)
                    } else if vm.isLoading {
                        ProgressView().tint(.white).scaleEffect(1.3).padding(.top, 160)
                    }
                }
                .frame(maxWidth: 600)          // 600 이상 안 늘어남
                .frame(maxWidth: .infinity)     // 남는 공간에서 가운데 정렬
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
                                .background {
                                        ZStack {
                                            Color.black
                                                .opacity(0.3)
                                                .blendMode(.softLight)
                                                
                                        }
                                    }
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 30, height: 30)
                            .background {
                                    ZStack {
                                        Color.black
                                            .opacity(0.3)
                                            .blendMode(.softLight)
                                            
                                    }
                                }
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                        VStack(alignment: .leading, spacing: 0) {
                            Toggle(isOn: $launchAtLogin) {
                                Text("시작 시 자동 실행")
                                    .font(.system(size: 13))
                            }
                            .toggleStyle(.switch)
                            .onChange(of: launchAtLogin) { _, v in
                                LaunchAtLogin.isEnabled = v
                            }
                            .padding(14)
                        }
                        .frame(width: 220)
                    }
                }
                .padding(.horizontal, 18).padding(.top, 14)
                Spacer()
            }
        }
        .frame(minWidth: 500, minHeight: 650)
        .preferredColorScheme(.dark)
        .task { await vm.loadData() }
        .sheet(isPresented: $showSearch) {
            MacSearchView(onSelect: { vm.selectLocation($0); showSearch = false },
                          onCancel: { showSearch = false })
        }
    }
    private func footer(_ d: StargazingData) -> String {
        var s = d.location.name
        if let a = d.location.admin1 { s += " · \(a)" }
        return s + " · Open-Meteo"
    }
}
