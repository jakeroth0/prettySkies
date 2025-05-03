import SwiftUI

/// Simple hex→Color initializer.
/// Trims non-hex chars, scans into UInt64, splits into RGBA.
extension Color {
    init(hex: String) {
        let hexClean = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&int)
        let r, g, b: UInt64
        if hexClean.count == 6 {
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        } else {
            (r, g, b) = (255, 255, 255)  // fallback white
        }
        print("[Color+Hex] Loaded hex:", hexClean, "→", r, g, b)
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: 1
        )
    }
}
