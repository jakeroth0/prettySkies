import SwiftUI

// MARK: - Double Extensions

extension Double {
    /// Clamps the value to the given range
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
} 