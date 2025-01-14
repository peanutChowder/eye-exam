import SwiftUI

struct ContentView: View {
    @State private var startExam = false

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Top logo/icon
                Image(systemName: "eye.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.customTheme.accentBlue)
                
                // Title
                Text("Eye Exam")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                
                Text("Quick Vision Screening")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Main action button
                Button(action: {
                    startExam = true
                }) {
                    Text("Start Eye Exam")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.customTheme.accentBlue)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .fullScreenCover(isPresented: $startExam) {
                    DistanceView()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
