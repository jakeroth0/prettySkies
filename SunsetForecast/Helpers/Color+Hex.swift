// SunsetForecast/Helpers/Color+Hex.swift

import SwiftUI

extension Color {
    /// Create a Color from a hex string (e.g. "#RRGGBB" or "RRGGBB").
    init(hex: String) {
        // Strip out any non-hex characters
        let hexClean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hexClean).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hexClean.count {
        case 6: // RRGGBB
            (r, g, b) = ((int >> 16) & 0xFF,
                         (int >> 8)  & 0xFF,
                         int         & 0xFF)
        default: // fallback white
            (r, g, b) = (255, 255, 255)
        }

        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: 1
        )
    }
}
