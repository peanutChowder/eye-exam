import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // Background color
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
                
                // Subtitle
                Text("Quick and accurate vision screening")
                    .font(.system(size: 16))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Main action button
                Button(action: {
                    // Add your eye exam start logic here
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
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
