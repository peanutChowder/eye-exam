import SwiftUI

struct SnellenRow {
    let visualAcuity: String  // fractional scale (e.g. 20/20)
    let letterCount: Int      // Num letters to be shown at this level
    let fontSize: CGFloat
}

class SnellenManager: ObservableObject {
    @Published private(set) var currentRow = 0
    @Published private(set) var currentLetterInRow = 0
    
    // snellen letters
    private let availableLetters = ["C", "D", "E", "F", "L", "N", "O", "P", "T", "Z"]
    
    private let rows = [
        SnellenRow(visualAcuity: "20/200", letterCount: 1, fontSize: 100),
        SnellenRow(visualAcuity: "20/100", letterCount: 2, fontSize: 70.7),
        SnellenRow(visualAcuity: "20/70", letterCount: 3, fontSize: 50),
        SnellenRow(visualAcuity: "20/50", letterCount: 4, fontSize: 35.4),
        SnellenRow(visualAcuity: "20/40", letterCount: 5, fontSize: 25),
        SnellenRow(visualAcuity: "20/30", letterCount: 6, fontSize: 17.7),
        SnellenRow(visualAcuity: "20/25", letterCount: 7, fontSize: 12.5),
        SnellenRow(visualAcuity: "20/20", letterCount: 8, fontSize: 8.9),
        SnellenRow(visualAcuity: "20/15", letterCount: 9, fontSize: 6.3)
    ]
    
    func getNextLetter() -> (letter: String, fontSize: CGFloat)? {
        guard currentRow < rows.count else { return nil }  // Test complete
        
        let row = rows[currentRow]
        
        // Get random letter (avoiding last used letter if possible)
        let letter = availableLetters.randomElement() ?? "E"
        
        // Advance position
        currentLetterInRow += 1
        if currentLetterInRow >= row.letterCount {
            currentRow += 1
            currentLetterInRow = 0
        }
        
        return (letter, row.fontSize)
    }
    
    func reset() {
        currentRow = 0
        currentLetterInRow = 0
    }
    
    var currentVisualAcuity: String {
        guard currentRow < rows.count else { return "Test Complete" }
        return rows[currentRow].visualAcuity
    }
}
