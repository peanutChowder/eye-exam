import SwiftUI

struct DistanceView: View {
    private let targetDistance: Float
    private let tolerance: Float
    
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var distanceChecker: DistanceChecker
    @State private var isReady = false
    
    init() {
        targetDistance = 0.3 // units in meters
        tolerance = 0.1
        
        let distanceCheckerObj = DistanceChecker(targetDistance: targetDistance, tolerance: tolerance)
        _distanceChecker = StateObject(wrappedValue: distanceCheckerObj)
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if distanceChecker.shouldStartExam {
                EyeExamView(distanceChecker: distanceChecker, targetDistance: targetDistance, tolerance: tolerance)
                    .transition(.opacity)
            } else {
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(12)
                        }
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                
                VStack(spacing: 20) {
                    // Meters display
                    if (!distanceChecker.isAtCorrectDistance) {
                        Text(String(format: "%.2f meters", distanceChecker.currentDistance))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    if let countdown = distanceChecker.countdownValue {
                        Text("Perfect! Hold this position")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                        Text("\(countdown)")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text(distanceChecker.isAtCorrectDistance ? "Perfect! Hold this position" : "Move closer or further")
                            .font(.system(size: 20))
                            .foregroundColor(distanceChecker.isAtCorrectDistance ? .green : .white)
                    }
                    
                    // Visual distance indicator
                    DistanceGuideView(currentDistance: distanceChecker.currentDistance,
                                      targetDistance: targetDistance,
                                      tolerance: tolerance)
                    .frame(height: 100)
                    .padding(.horizontal)
                }
                .animation(.easeInOut, value: distanceChecker.countdownValue)
                .animation(.easeInOut, value: distanceChecker.isAtCorrectDistance)
            }
        }
        .onAppear {
            distanceChecker.startDistanceCheck()
        }
        .onDisappear {
            distanceChecker.stopDistanceCheck()
        }
    }
}

// Guide view to show users how close they are
struct DistanceGuideView: View {
    let currentDistance: Float
    let targetDistance: Float
    let tolerance: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .cornerRadius(8)
                
                // Target zone band
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 40)
                    .offset(x: CGFloat((targetDistance / 2) * Float(geometry.size.width)) - 20)
                
                // Current position indicator
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4)
                    .offset(x: CGFloat((currentDistance / 2) * Float(geometry.size.width)) - 2)
            }
        }
    }
}

struct ExamPage_Previews: PreviewProvider {
    static var previews: some View {
        DistanceView()
    }
}
