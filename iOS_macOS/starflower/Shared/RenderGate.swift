//
//  RenderGate.swift
//  starflower
//
//  Created by 양지성 on 9/15/26.
//

import SwiftUI
import Combine

@MainActor
final class RenderGate: ObservableObject {
    static let shared = RenderGate()
    @Published var isActive = true
}
