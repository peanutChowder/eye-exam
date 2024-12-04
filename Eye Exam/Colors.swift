import SwiftUI

extension Color {
    static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        return Color(red: red/255, green: green/255, blue: blue/255)
    }
    
    static let customTheme = CustomTheme()
    
    struct CustomTheme {
        let accentBlue = Color.rgb(76, 173, 173)
        
    }
}
