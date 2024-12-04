import SwiftUI

struct ExamPage: View {
    @StateObject private var viewModel = DistanceChecker()
    @State private var isReady = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Distance indicator
                Text(String(format: "%.2f meters", viewModel.currentDistance))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Status message
                Text(viewModel.isAtCorrectDistance ? "Perfect! Hold this position" : "Move closer or further")
                    .font(.system(size: 20))
                    .foregroundColor(viewModel.isAtCorrectDistance ? .green : .white)
                
                // Distance guide
                DistanceGuideView(currentDistance: viewModel.currentDistance,
                                targetDistance: 1.0,
                                tolerance: 0.1)
                    .frame(height: 100)
                    .padding(.horizontal)
            }
        }
        .onAppear {
            viewModel.startDistanceCheck()
        }
        .onDisappear {
            viewModel.stopDistanceCheck()
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
        ExamPage()
    }
}
