import SwiftUI

struct EyeExamView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var distanceChecker: DistanceChecker
    @StateObject private var snellenManager = SnellenManager()
    
    // State to store current letter and size
    @State private var currentLetter: String = "E"
    @State private var currentFontSize: CGFloat = 100
    
    // Voice recognition
    @StateObject private var speechRecognizer = SnellenSpeechRecognizer()
    @State private var isListening = false
    
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
            
            // Close button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(distanceChecker.isAtCorrectDistance ? .black.opacity(0.7) : .white.opacity(0.7))
                            .padding(12)
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 8)
                
                Spacer()
            }
            
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
        .onAppear {
            setupSpeechRecognition()
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
    
    private func setupSpeechRecognition() {
        // callback function -- move to next letter whevever a snellen letter is recognized
        speechRecognizer.onLetterRecognized = { recognizedLetter in
            DispatchQueue.main.async {
                advanceToNextLetter()
            }
        }
        speechRecognizer.startRecording() // Start recording for first letter right away
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
