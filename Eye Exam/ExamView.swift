import SwiftUI

struct EyeExamView: View {
    @ObservedObject var distanceChecker: DistanceChecker
    
    let targetDistance: Float
    let tolerance: Float
    
    private let letter = "E"
    private let fontSize: CGFloat = 100
    
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
                    Text(letter)
                        .font(.custom("Helvetica", size: fontSize))
                        .foregroundColor(.black)
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
    
    private func getDistanceWarning() -> String {
        let currentDistance = distanceChecker.currentDistance
        
        if ((currentDistance - targetDistance) > tolerance) {
            return "Too far away\nPlease move closer"
        } else {
            return "Too close\nPlease move back"
        }
    }
}


// future TODO
struct SnellenLetter {
    let character: String
    let size: CGFloat
    let rowLevel: Int
}
