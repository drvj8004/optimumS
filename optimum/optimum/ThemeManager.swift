import SwiftUI

/// Keeps the accent colour and persists it via UserDefaults.
final class ThemeManager: ObservableObject {

    // Raw storage
    @AppStorage("themeR") private var storedR: Double = 0.20
    @AppStorage("themeG") private var storedG: Double = 0.80
    @AppStorage("themeB") private var storedB: Double = 0.20

    // Published values (initially zero, then overwritten in init)
    @Published var r: Double = 0
    @Published var g: Double = 0
    @Published var b: Double = 0

    init() {
        // Copy persisted values after all props exist
        r = storedR
        g = storedG
        b = storedB
    }

    /// Call after editing r/g/b to store them
    func commit() {
        storedR = r
        storedG = g
        storedB = b
    }

    /// Convenience colour
    var color: Color { Color(red: r, green: g, blue: b) }
}
