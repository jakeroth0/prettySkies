import SwiftUI

/// Provides dynamic gradient color stops based on sunset score
struct GradientHelper {
    /// Returns an array of three Color stops for the given sunset score.
    /// - Parameter score: The sunset score (0-100, or nil for default)
    /// - Returns: Array of three Color stops for the gradient
    static func gradientColorsForScore(_ score: Int?) -> [Color] {
        guard let score = score else {
            // Default: Good range
            return [
                Color(hex: "#FF7E5F"), // top
                Color(hex: "#FEB47B"), // middle
                Color(hex: "#FFB35C")  // bottom
            ]
        }
        switch score {
        case 80...:
            // Excellent: Fiery, saturated
            return [
                Color(hex: "#FF5E3A"), // top
                Color(hex: "#FF2A68"), // middle
                Color(hex: "#FF6B5C")  // bottom
            ]
        case 50...79:
            // Good: Warm pinks/oranges
            return [
                Color(hex: "#FF7E5F"), // top
                Color(hex: "#FEB47B"), // middle
                Color(hex: "#FFB35C")  // bottom
            ]
        case 1...49:
            // Mediocre: Gentle pastels
            return [
                Color(hex: "#FFD194"), // top
                Color(hex: "#D1913C"), // middle
                Color(hex: "#E0C3FC")  // bottom
            ]
        default:
            // Poor (0 or negative): Muted grays
            return [
                Color(hex: "#6E6E6E"), // top
                Color(hex: "#9E9E9E"), // middle
                Color(hex: "#BDBDBD")  // bottom
            ]
        }
    }
} 