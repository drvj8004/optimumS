
import SwiftUI
/// Global accent‑colour manager (persisted with @AppStorage).
final class ThemeManager: ObservableObject {
    @AppStorage("theme_r") var r: Double = 0.25
    @AppStorage("theme_g") var g: Double = 0.6
    @AppStorage("theme_b") var b: Double = 1.0

    var color: Color { Color(red: r, green: g, blue: b) }

    func commit() { objectWillChange.send() }
}
