//
//  RenderGate.swift
//  starflower
//

import SwiftUI
import Combine

@MainActor
final class RenderGate: ObservableObject {
    static let shared = RenderGate()
    @Published var isActive = true
}
