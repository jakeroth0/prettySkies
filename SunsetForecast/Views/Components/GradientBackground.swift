import SwiftUI

/// A reusable background view that displays a dynamic gradient based on a sunset score
struct GradientBackground: View {
    let score: Int?
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: GradientHelper.gradientColorsForScore(score)),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    VStack {
        GradientBackground(score: 85) // Excellent score
        GradientBackground(score: 65) // Good score
        GradientBackground(score: 25) // Mediocre score
        GradientBackground(score: 0)  // Poor score
        GradientBackground(score: nil) // Default
    }
} 