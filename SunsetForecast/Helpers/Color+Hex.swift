// SunsetForecast/Helpers/Color+Hex.swift
import SwiftUI

extension Color {
    /// Initialize a SwiftUI Color from a hex string like "#RRGGBB"
    init(hex: String) {
        let hexClean = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&int)
        let r, g, b: UInt64
        if hexClean.count == 6 {
            r = (int >> 16) & 0xFF
            g = (int >> 8)  & 0xFF
            b = int & 0xFF
        } else {
            r = 1; g = 1; b = 1
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: 1
        )
    }
}
