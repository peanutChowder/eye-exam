import UIKit

class SnellenSizeCalculator {
    // Standard Snellen letter height for 20/20 vision subtends 5 arc minutes
    private static let standardAngleMinutes: Double = 5
    private static let screenPPIs: [String: Float] = [
         // iPhone 15 Series
         "iPhone16,1": 460, // iPhone 15 Pro
         "iPhone16,2": 460, // iPhone 15 Pro Max
         "iPhone15,4": 460, // iPhone 15
         "iPhone15,5": 458, // iPhone 15 Plus
         
         // iPhone 14 Series
         "iPhone14,7": 460, // iPhone 14
         "iPhone14,8": 458, // iPhone 14 Plus
         "iPhone15,2": 460, // iPhone 14 Pro
         "iPhone15,3": 460, // iPhone 14 Pro Max
         
         // iPhone 13 Series
         "iPhone14,5": 460, // iPhone 13
         "iPhone14,4": 476, // iPhone 13 mini
         "iPhone14,2": 460, // iPhone 13 Pro
         "iPhone14,3": 458, // iPhone 13 Pro Max
         
         // iPhone 12 Series
         "iPhone13,1": 476, // iPhone 12 mini
         "iPhone13,2": 460, // iPhone 12
         "iPhone13,3": 460, // iPhone 12 Pro
         "iPhone13,4": 458, // iPhone 12 Pro Max
         
         // iPhone 11 Series
         "iPhone12,1": 326, // iPhone 11
         "iPhone12,3": 458, // iPhone 11 Pro
         "iPhone12,5": 458, // iPhone 11 Pro Max
         
         // iPad Pro Series (2020-2024)
         "iPad13,4": 264, // iPad Pro 11-inch (3rd gen)
         "iPad13,5": 264, // iPad Pro 11-inch (3rd gen)
         "iPad13,6": 264, // iPad Pro 11-inch (3rd gen)
         "iPad13,7": 264, // iPad Pro 11-inch (3rd gen)
         "iPad13,8": 264, // iPad Pro 12.9-inch (5th gen)
         "iPad13,9": 264, // iPad Pro 12.9-inch (5th gen)
         "iPad13,10": 264, // iPad Pro 12.9-inch (5th gen)
         "iPad13,11": 264, // iPad Pro 12.9-inch (5th gen)
         "iPad14,3": 264, // iPad Pro 11-inch (4th gen)
         "iPad14,4": 264, // iPad Pro 11-inch (4th gen)
         "iPad14,5": 264, // iPad Pro 12.9-inch (6th gen)
         "iPad14,6": 264, // iPad Pro 12.9-inch (6th gen)
         
         // iPad Air Series (2020-2024)
         "iPad13,1": 264, // iPad Air (4th gen)
         "iPad13,2": 264, // iPad Air (4th gen)
         "iPad13,16": 264, // iPad Air (5th gen)
         "iPad13,17": 264, // iPad Air (5th gen)
         
         // iPad Mini Series (2021-2024)
         "iPad14,1": 326, // iPad mini (6th gen)
         "iPad14,2": 326  // iPad mini (6th gen)
     ]
    
    static func calculateFontSize(
        for visualAcuity: String,
        at distanceMeters: Float
    ) -> CGFloat {
        Logger.group("Snellen Font Calculation")
        let distanceInches = distanceMeters * 39.3701
        let screenPPI = getScreenPPI();
        let acuityRatio = parseVisualAcuity(visualAcuity)
        
        let angleInRadians = (standardAngleMinutes / 60.0) * (Double.pi / 180.0)        // Convert 5 arc minutes to radians
        let heightInches = Double(distanceInches) * tan(angleInRadians) // Calculate letter height
        let scaledHeightInches = heightInches * acuityRatio  // Scale by acuity ratio
        let heightInPixels = scaledHeightInches * Double(screenPPI) // Convert to pixels
        
        let scale = UIScreen.main.scale     // Calc points based on device pixel to points ratio
        let points = CGFloat(heightInPixels / Double(scale))
        
        Logger.log("Distance: \(distanceInches) in")
        Logger.log("Device PPI: \(screenPPI)")
        Logger.log("Acuity: \(visualAcuity)")
        Logger.log("Font size: \(points) points, \(scaledHeightInches) inches")
        Logger.groupEnd()
        
        return points
    }
    
    private static func parseVisualAcuity(_ acuity: String) -> Double {
        let components = acuity.split(separator: "/")
        guard components.count == 2,
              let numerator = Double(components[0]),
              let denominator = Double(components[1]) else {
            debugPrint("parseVisualAcuity failed")
            return 1.0 // Default to 20/20 if parsing fails
        }
        
        return denominator / numerator
    }
    
    
    static func getScreenPPI() -> Float {
        var systemInfo = utsname()
        uname(&systemInfo)

        
        let machineMirror = Mirror(reflecting: systemInfo.machine) // Machine ID used by apple
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return screenPPIs[identifier] ?? 0.0
    }
}
