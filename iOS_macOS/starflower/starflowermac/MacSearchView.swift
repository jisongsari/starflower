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
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(results) { r in
                            Button { onSelect(r) } label: {
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
