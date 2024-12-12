class Logger {
    private static var groupLevel = 0

    static func group(_ title: String) {
        print(String(repeating: " ", count: groupLevel * 4) + "\(title)")
        groupLevel += 1
    }

    static func groupEnd(_ endMsg: String = "") {
        groupLevel = max(0, groupLevel - 1)
        print(String(repeating: " ", count: groupLevel * 4) + endMsg)
    }

    static func log(_ message: String) {
        print(String(repeating: " ", count: groupLevel * 4) + message)
    }
    
    static func rlog(_ message: String) {
        print("| ", message)
    }
}
