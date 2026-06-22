//
//  MacSearchView.swift
//  starflower
//
//  Created by 양지성 on 6/22/26.
//


import SwiftUI

struct MacSearchView: View {
    let onSelect: (GeoResult) -> Void
    let onCancel: () -> Void

    @State private var query = ""
    @State private var results: [GeoResult] = []
    @State private var loading = false
    @State private var hint: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("수원시, 제주시, 광양시 ...", text: $query)
                    .textFieldStyle(.plain)
                    .onChange(of: query) { _, v in Task { await run(v) } }
                Button("취소") { onCancel() }
            }
            .padding(12)

            Divider()

            if loading {
                ProgressView().controlSize(.small).padding(30); Spacer()
            } else if let h = hint {
                Text(h).font(.callout).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(30); Spacer()
            } else {
                List(results) { r in
                    Button {
                        onSelect(r)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.name).font(.system(size: 15, weight: .semibold))
                            if !r.displayName.isEmpty {
                                Text(r.displayName).font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 380, height: 460)
    }

    private func run(_ q: String) async {
        let t = q.trimmingCharacters(in: .whitespaces)
        guard t.count >= 2 else { results = []; hint = nil; loading = false; return }
        loading = true; hint = nil
        try? await Task.sleep(nanoseconds: 500_000_000)
        guard query.trimmingCharacters(in: .whitespaces) == t else { return }
        let r = await GeoService.shared.search(query: t)
        results = r
        hint = r.isEmpty ? "검색 결과가 없어요." : nil
        loading = false
    }
}