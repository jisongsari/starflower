//
//  MacSearchView.swift
//  starflower
//
//  Created by 양지성 on 6/22/26.
//


import SwiftUI
import AppKit

struct MacSearchView: View {
    let onSelect: (GeoResult) -> Void
    let onCancel: () -> Void

    @State private var query = ""
    @State private var results: [GeoResult] = []
    @State private var loading = false
    @State private var hint: String?
    @State private var hoverID: Int?
    @State private var recents: [GeoResult] = []
    private let recentsKey = "starflower.recentSearches.mac.v1"

    var body: some View {
        VStack(spacing: 0) {
            // 검색 바
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("수원시, 제주시, 광양시 ...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .onChange(of: query) { _, v in Task { await run(v) } }
                if !query.isEmpty {
                    Button { query = ""; results = []; hint = nil } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }.buttonStyle(.plain)
                }
                Button("취소") { onCancel() }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.rgba(142,162,255,1))
            }
            .padding(12)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(14)

            Divider()

            // 결과
            if loading {
                Spacer()
                ProgressView().controlSize(.small)
                Spacer()
            } else if let h = hint {
                Spacer()
                Text(h).font(.callout).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 30)
                Spacer()
            } else if query.trimmingCharacters(in: .whitespaces).count < 2 {
                if recents.isEmpty {
                    Spacer()
                    Text("관측할 지역을 검색해 보세요.\n정확한 결과를 위해 수원시, 제주시처럼 '시·군·구'까지 입력해 주세요.")
                        .font(.callout).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 30)
                    Spacer()
                } else {
                    recentListView
                }
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(results) { r in
                            Button { onSelect(r); RecentSearchStore.add(r, key: recentsKey) } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(r.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    let meta = [r.admin1, r.country].compactMap { $0 }.joined(separator: ", ")
                                    if !meta.isEmpty {
                                        Text(meta)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 9)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.primary.opacity(hoverID == r.id ? 0.08 : 0))
                                )
                            }
                            .buttonStyle(.plain)
                            .onHover { hoverID = $0 ? r.id : nil }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 380, height: 460)
        .background(VisualEffectBackground(material: .popover, blending: .behindWindow))
        .onAppear { recents = RecentSearchStore.load(key: recentsKey) }
    }

    private var recentListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("최근 검색")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("전체 삭제") {
                    RecentSearchStore.clear(key: recentsKey)
                    recents = []
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(Color.rgba(142,162,255,1))
            }
            .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(recents) { r in
                        Button {
                            onSelect(r)
                            RecentSearchStore.add(r, key: recentsKey)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "clock").font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(r.name).font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    let meta = [r.admin1, r.country].compactMap { $0 }.joined(separator: ", ")
                                    if !meta.isEmpty {
                                        Text(meta).font(.system(size: 12)).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 9).padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.primary.opacity(hoverID == r.id ? 0.08 : 0))
                            )
                        }
                        .buttonStyle(.plain)
                        .onHover { hoverID = $0 ? r.id : nil }
                        .contextMenu {
                            Button("삭제") {
                                RecentSearchStore.remove(r, key: recentsKey)
                                recents.removeAll { $0.id == r.id }
                            }
                        }
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
            }
        }
    }
    
    private func run(_ q: String) async {
        let t = q.trimmingCharacters(in: .whitespaces)
        guard t.count >= 2 else { results = []; hint = nil; loading = false; return }
        loading = true; hint = nil
        try? await Task.sleep(nanoseconds: 500_000_000)
        guard query.trimmingCharacters(in: .whitespaces) == t else { return }
        let r = await GeoService.shared.search(query: t)
        results = r
        hint = r.isEmpty ? "검색 결과가 없어요.\n다른 이름으로 찾아보세요." : nil
        loading = false
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blending: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blending
        v.state = .active
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material = material
        v.blendingMode = blending
    }
}
