//
//  SearchView.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import SwiftUI

struct SearchView: View {
    let onSelect: (GeoResult) -> Void
    let dismissable: Bool

    @State private var query = ""
    @State private var results: [GeoResult] = []
    @State private var loading = false
    @State private var hint: String?
    @Environment(\.dismiss) private var dismiss
    @State private var recents: [GeoResult] = []
    private let recentsKey = "starflower.recentSearches.v1"

    var body: some View {
        ZStack {
            Color.rgba(8,10,22,0.92).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.7))
                    TextField("", text: $query, prompt: Text("수원시, 제주시, 광양시 ...")
                        .foregroundStyle(.white.opacity(0.5)))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .onChange(of: query) { _, v in Task { await runSearch(v) } }
                    if !query.isEmpty {
                        Button { query = ""; results = []; hint = nil } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    if dismissable {
                        Button("취소") { dismiss() }
                            .foregroundStyle(Color.rgba(142,162,255,1))
                    }
                }
                .padding(11)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.16), lineWidth: 1))
                .padding(.horizontal, 16).padding(.top, 18)

                if loading {
                    hintView("검색 중…"); Spacer()
                } else if let h = hint {
                    hintView(h); Spacer()
                } else if query.trimmingCharacters(in: .whitespaces).count < 2 {
                    if recents.isEmpty {
                        hintView("관측할 지역을 검색해 보세요.\n정확한 결과를 위해 수원시, 제주시처럼 '시·군·구'까지 입력해 주세요.")
                        Spacer()
                    } else {
                        recentListView
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(results) { r in
                                Button {
                                    onSelect(r)
                                    RecentSearchStore.add(r, key: recentsKey)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(r.name).font(.system(size: 17, weight: .semibold))
                                            .foregroundStyle(.white)
                                        if !r.displayName.isEmpty {
                                            Text(r.displayName).font(.system(size: 13))
                                                .foregroundStyle(.white.opacity(0.55))
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 13).padding(.horizontal, 8)
                                }
                                Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 12)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .preferredColorScheme(.dark)
        .onAppear { recents = RecentSearchStore.load(key: recentsKey) }
    }

    private func hintView(_ s: String) -> some View {
        Text(s).font(.system(size: 14)).foregroundStyle(.white.opacity(0.6))
            .multilineTextAlignment(.center).lineSpacing(3)
            .frame(maxWidth: .infinity).padding(.horizontal, 24).padding(.top, 40)
    }
    
    private var recentListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("최근 검색")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 8).padding(.top, 4).padding(.bottom, 6)
                ForEach(recents) { r in
                    Button {
                        onSelect(r)
                        RecentSearchStore.add(r, key: recentsKey)
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "clock").font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.4))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.name).font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                if !r.displayName.isEmpty {
                                    Text(r.displayName).font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 11).padding(.horizontal, 8)
                    }
                    Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
                }
            }
            .padding(.horizontal, 16).padding(.top, 8)
        }
    }

    private func runSearch(_ q: String) async {
        let t = q.trimmingCharacters(in: .whitespaces)
        guard t.count >= 2 else { results = []; hint = nil; loading = false; return }
        loading = true; hint = nil
        try? await Task.sleep(nanoseconds: 500_000_000)
        guard query.trimmingCharacters(in: .whitespaces) == t else { return }
        let r = await GeoService.shared.search(query: t)
        guard query.trimmingCharacters(in: .whitespaces) == t else { return }
        results = r
        hint = r.isEmpty ? "검색 결과가 없어요. 다른 이름으로 찾아보세요." : nil
        loading = false
    }
}
