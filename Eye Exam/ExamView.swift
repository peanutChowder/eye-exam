import SwiftUI

struct EyeExamView: View {
    @ObservedObject var distanceChecker: DistanceChecker
    @StateObject private var snellenManager = SnellenManager()
    
    // State to store current letter and size
    @State private var currentLetter: String = "E"
    @State private var currentFontSize: CGFloat = 100
    
    let targetDistance: Float
    let tolerance: Float
    
    var body: some View {
        ZStack {
            Group {
                if distanceChecker.isAtCorrectDistance {
                    Color.white
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea()
            
            // Warn user if they are too close/far
            if distanceChecker.isAtCorrectDistance {
                // Exam content
                VStack {
                    Text(currentLetter)
                        .font(.custom("Helvetica", size: currentFontSize))
                        .foregroundColor(.black)
                    
                    Text(snellenManager.currentVisualAcuity)
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                }
                .onTapGesture {
                    advanceToNextLetter()
                }
            } else {
                // Distance warning
                VStack {
                    Text(getDistanceWarning())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .animation(.easeInOut, value: distanceChecker.isAtCorrectDistance)
    }
    
    private func advanceToNextLetter() {
        if let nextLetter = snellenManager.getNextLetter(targetDistance: targetDistance) {
            currentLetter = nextLetter.letter
            currentFontSize = nextLetter.fontSize
        } else {
            // TODO: add completion view
            snellenManager.reset()
            currentLetter = "E"
            currentFontSize = SnellenSizeCalculator.calculateFontSize(
                for: "20/200",
                at: targetDistance
            )
        }
    }
    
    private func getDistanceWarning() -> String {
        let currentDistance = distanceChecker.currentDistance
        
        if ((currentDistance - targetDistance) > tolerance) {
            return "Too far away\nPlease move closer"
        } else {
            return "Too close\nPlease move back"
        }
    }
}
