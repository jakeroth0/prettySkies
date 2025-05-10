import XCTest
@testable import SunsetForecast

/// Tests for the GradientHelper struct functionality
final class GradientHelperTests: XCTestCase {
    
    // MARK: - Tests for gradientColorsForScore
    
    func testGradientColorsForExcellentScore() {
        // Given a score in the excellent range (80-100)
        let score = 85
        
        // When we get colors for this score
        let colors = GradientHelper.gradientColorsForScore(score)
        
        // Then we expect fiery, saturated colors
        XCTAssertEqual(colors.count, 3, "Should return exactly 3 colors")
        XCTAssertEqual(colors[0], Color(hex: "#FF5E3A"), "First color should match excellent range top color")
        XCTAssertEqual(colors[1], Color(hex: "#FF2A68"), "Second color should match excellent range middle color")
        XCTAssertEqual(colors[2], Color(hex: "#FF6B5C"), "Third color should match excellent range bottom color")
    }
    
    func testGradientColorsForGoodScore() {
        // Given a score in the good range (50-79)
        let score = 65
        
        // When we get colors for this score
        let colors = GradientHelper.gradientColorsForScore(score)
        
        // Then we expect warm pinks/oranges
        XCTAssertEqual(colors.count, 3, "Should return exactly 3 colors")
        XCTAssertEqual(colors[0], Color(hex: "#FF7E5F"), "First color should match good range top color")
        XCTAssertEqual(colors[1], Color(hex: "#FEB47B"), "Second color should match good range middle color")
        XCTAssertEqual(colors[2], Color(hex: "#FFB35C"), "Third color should match good range bottom color")
    }
    
    func testGradientColorsForMediocreScore() {
        // Given a score in the mediocre range (1-49)
        let score = 25
        
        // When we get colors for this score
        let colors = GradientHelper.gradientColorsForScore(score)
        
        // Then we expect gentle pastels
        XCTAssertEqual(colors.count, 3, "Should return exactly 3 colors")
        XCTAssertEqual(colors[0], Color(hex: "#FFD194"), "First color should match mediocre range top color")
        XCTAssertEqual(colors[1], Color(hex: "#D1913C"), "Second color should match mediocre range middle color")
        XCTAssertEqual(colors[2], Color(hex: "#E0C3FC"), "Third color should match mediocre range bottom color")
    }
    
    func testGradientColorsForPoorScore() {
        // Given a score of 0 (poor conditions)
        let score = 0
        
        // When we get colors for this score
        let colors = GradientHelper.gradientColorsForScore(score)
        
        // Then we expect muted grays
        XCTAssertEqual(colors.count, 3, "Should return exactly 3 colors")
        XCTAssertEqual(colors[0], Color(hex: "#6E6E6E"), "First color should match poor range top color")
        XCTAssertEqual(colors[1], Color(hex: "#9E9E9E"), "Second color should match poor range middle color")
        XCTAssertEqual(colors[2], Color(hex: "#BDBDBD"), "Third color should match poor range bottom color")
    }
    
    func testGradientColorsForNilScore() {
        // Given a nil score
        let score: Int? = nil
        
        // When we get colors for this score
        let colors = GradientHelper.gradientColorsForScore(score)
        
        // Then we expect default mid-range colors
        XCTAssertEqual(colors.count, 3, "Should return exactly 3 colors")
        XCTAssertEqual(colors[0], Color(hex: "#FF7E5F"), "First color should match default range top color")
        XCTAssertEqual(colors[1], Color(hex: "#FEB47B"), "Second color should match default range middle color")
        XCTAssertEqual(colors[2], Color(hex: "#FFB35C"), "Third color should match default range bottom color")
    }
    
    // MARK: - Tests for edge cases
    
    func testGradientColorsForBoundaryScores() {
        // Test lower boundary of excellent range (80)
        XCTAssertEqual(
            GradientHelper.gradientColorsForScore(80)[0], 
            Color(hex: "#FF5E3A"),
            "Score of 80 should return excellent range colors"
        )
        
        // Test upper boundary of good range (79)
        XCTAssertEqual(
            GradientHelper.gradientColorsForScore(79)[0], 
            Color(hex: "#FF7E5F"),
            "Score of 79 should return good range colors"
        )
        
        // Test lower boundary of good range (50)
        XCTAssertEqual(
            GradientHelper.gradientColorsForScore(50)[0], 
            Color(hex: "#FF7E5F"),
            "Score of 50 should return good range colors"
        )
        
        // Test upper boundary of mediocre range (49)
        XCTAssertEqual(
            GradientHelper.gradientColorsForScore(49)[0], 
            Color(hex: "#FFD194"),
            "Score of 49 should return mediocre range colors"
        )
        
        // Test lower boundary of mediocre range (1)
        XCTAssertEqual(
            GradientHelper.gradientColorsForScore(1)[0], 
            Color(hex: "#FFD194"),
            "Score of 1 should return mediocre range colors"
        )
    }
    
    func testGradientColorsForInvalidScores() {
        // Test negative score
        XCTAssertEqual(
            GradientHelper.gradientColorsForScore(-10)[0], 
            Color(hex: "#6E6E6E"),
            "Negative score should return poor range colors"
        )
        
        // Test score exceeding 100
        XCTAssertEqual(
            GradientHelper.gradientColorsForScore(150)[0], 
            Color(hex: "#FF5E3A"),
            "Score over 100 should return excellent range colors"
        )
    }
} 