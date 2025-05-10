import SwiftUI

/// Provides dynamic gradient color stops based on sunset score
struct GradientHelper {
    /// Default sunset colors if no score is available
    static let defaultGradient = [
        Color("#FF7E5F"), // top
        Color("#FEB47B"), // middle
        Color("#FFB35C")  // bottom
    ]
    
    /// Returns a gradient color scheme based on the provided sunset score
    static func gradientColorsForScore(_ score: Int?) -> [Color] {
        guard let score = score else { return defaultGradient }
        
        if score >= 80 {
            return [
                Color("#FF5E3A"), // top
                Color("#FF2A68"), // middle
                Color("#FF6B5C")  // bottom
            ]
        } else if score >= 60 {
            return [
                Color("#FF7E5F"), // top
                Color("#FEB47B"), // middle
                Color("#FFB35C")  // bottom
            ]
        } else if score >= 40 {
            return [
                Color("#FFD194"), // top
                Color("#D1913C"), // middle
                Color("#E0C3FC")  // bottom
            ]
        } else {
            return [
                Color("#6E6E6E"), // top
                Color("#9E9E9E"), // middle
                Color("#BDBDBD")  // bottom
            ]
        }
    }
} 