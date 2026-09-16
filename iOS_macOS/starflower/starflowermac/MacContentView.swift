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
    // MenuBarExtra(isInserted:) 가 이 값을 구독한다. 끄면 메뉴 막대에서 즉시 사라지고,
    // 그 상태에서 창을 닫으면 MainWindowController 가 앱을 종료한다.
    @AppStorage(MenuBarVisibility.key) private var showMenuBarExtra = true

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
                        // Toggle 은 제 크기만큼만 차지해서 고정 폭 안에 두면 오른쪽이 비어 보인다.
                        // 라벨과 스위치를 직접 HStack 으로 벌려 양 끝에 붙인다.
                        VStack(spacing: 0) {
                            settingRow("시작 시 자동 실행", isOn: $launchAtLogin)
                                .onChange(of: launchAtLogin) { _, v in
                                    LaunchAtLogin.isEnabled = v
                                }

                            Divider().padding(.horizontal, 14)

                            // @AppStorage 가 UserDefaults 에 바로 쓰고 MenuBarExtra 가 그 값을
                            // 구독하므로 onChange 가 필요 없다.
                            settingRow("메뉴 막대에 표시", isOn: $showMenuBarExtra)
                        }
                        .frame(width: 240)
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
    private func settingRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(title).font(.system(size: 13))
            Spacer(minLength: 0)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func footer(_ d: StargazingData) -> String {
        var s = d.location.name
        if let a = d.location.admin1 { s += " · \(a)" }
        return s + " · Open-Meteo"
    }
}
