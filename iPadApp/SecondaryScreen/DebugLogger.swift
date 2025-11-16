import Foundation
import SwiftUI

class DebugLogger: ObservableObject {
    @Published var logs: String = ""
    private let dateFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        log("🚀 Debug logger initialized")
    }
    
    func log(_ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let logLine = "[\(timestamp)] \(message)\n"
        
        DispatchQueue.main.async {
            self.logs += logLine
        }
        
        // Also print to Xcode console
        print(message)
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs = ""
            self.log("🧹 Console cleared")
        }
    }
}
