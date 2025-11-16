import Foundation
import Network
import UIKit

class ConnectionManager: ObservableObject {
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var isSearching = false
    @Published var availableDevices: [DeviceInfo] = []
    @Published var currentFrame: UIImage?
    @Published var errorMessage: String?
    @Published var settings = AppSettings()
    @Published var debugLogger = DebugLogger()
    
    let deviceId = UUID().uuidString
    
    private var connection: NWConnection?
    private var browser: NWBrowser?
    private let queue = DispatchQueue(label: "com.secondaryscreen.network")
    private var receiveBuffer = Data()
    
    init() {
        debugLogger.log("🚀 ConnectionManager initialized")
        debugLogger.log("📱 Device ID: \(deviceId)")
        debugLogger.log("📍 Device: \(UIDevice.current.name)")
        
        loadSettings()
        if settings.autoConnect {
            debugLogger.log("🔄 Auto-connect enabled, starting search...")
            startSearching()
        }
    }
    
    func startSearching() {
        isSearching = true
        debugLogger.log("🔍 Starting device search...")
        errorMessage = nil
        
        // Start Bonjour/mDNS browser
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browser = NWBrowser(for: .bonjour(type: "_secondaryscreen._tcp", domain: nil), using: parameters)
        self.browser = browser
        
        browser.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .failed(let error):
                    self?.errorMessage = "Search failed: \(error.localizedDescription)"
                    self?.isSearching = false
                case .ready:
                    break
                default:
                    break
                }
            }
        }
        
        browser.browseResultsChangedHandler = { [weak self] results, changes in
            DispatchQueue.main.async {
                self?.availableDevices = results.compactMap { result -> DeviceInfo? in
                    guard case .service(let name, _, _, _) = result.endpoint else {
                        return nil
                    }
                    return DeviceInfo(id: UUID().uuidString, name: name, ipAddress: "", connectionType: "WiFi")
                }
            }
        }
        
        browser.start(queue: queue)
        
        // Stop searching after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.isSearching = false
        }
    }
    
    func connectToDevice(_ device: DeviceInfo) {
        connectManually(to: device.ipAddress)
    }
    
    func connectManually(to ipAddress: String) {
        errorMessage = nil
        isConnecting = true
        
        debugLogger.log("🔌 Connecting to \(ipAddress):4000...")
        
        let host = NWEndpoint.Host(ipAddress)
        let port = NWEndpoint.Port(integerLiteral: 4000)
        
        let connection = NWConnection(host: host, port: port, using: .tcp)
        self.connection = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.debugLogger.log("✅ Connected successfully!")
                    self?.isConnected = true
                    self?.isConnecting = false
                    self?.errorMessage = nil
                    self?.startReceiving()
                    self?.sendDeviceInfo()
                case .failed(let error):
                    self?.debugLogger.log("❌ Connection failed: \(error.localizedDescription)")
                    self?.errorMessage = "Cannot connect to \(ipAddress)\n\n✓ Check PC is running the server\n✓ Check both on same WiFi\n✓ Check IP address is correct"
                    self?.isConnected = false
                    self?.isConnecting = false
                case .waiting(let error):
                    self?.debugLogger.log("⏳ Waiting to connect: \(error.localizedDescription)")
                    self?.errorMessage = "Waiting to connect..."
                    self?.isConnecting = true
                case .cancelled:
                    self?.debugLogger.log("🚫 Connection cancelled")
                    self?.isConnecting = false
                default:
                    break
                }
            }
        }
        
        connection.start(queue: queue)
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
        currentFrame = nil
        errorMessage = nil
    }
    
    private func sendDeviceInfo() {
        let info: [String: Any] = [
            "type": "info",
            "deviceId": deviceId,
            "deviceName": UIDevice.current.name,
            "deviceModel": UIDevice.current.model
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: info),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            sendMessage(jsonString)
        }
    }
    
    private func sendMessage(_ message: String) {
        guard let connection = connection else { return }
        
        let data = (message + "\n").data(using: .utf8)!
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.debugLogger.log("Send error: \(error)")
            }
        })
    }
    
    private func startReceiving() {
        receiveMessage()
    }
    
    private func receiveMessage() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.debugLogger.log("📨 Received \(data.count) bytes")
                
                // CRITICAL: Prevent buffer overflow - limit to 10MB
                if let bufferSize = self?.receiveBuffer.count, bufferSize > 10_000_000 {
                    self?.debugLogger.log("⚠️ Buffer overflow! Size: \(bufferSize) bytes - clearing old data")
                    self?.receiveBuffer.removeAll()
                }
                
                self?.receiveBuffer.append(data)
                self?.processReceivedData()
            }
            
            if let error = error {
                self?.debugLogger.log("❌ Receive error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.errorMessage = "Receive error: \(error.localizedDescription)"
                }
                return
            }
            
            // Always continue receiving unless there was an error
            self?.receiveMessage()
        }
    }
    
    private func processReceivedData() {
        // Look for newline-delimited JSON messages
        debugLogger.log("🔍 Processing buffer: \(receiveBuffer.count) bytes")
        
        while let newlineRange = receiveBuffer.range(of: "\n".data(using: .utf8)!) {
            let messageData = receiveBuffer.subdata(in: 0..<newlineRange.lowerBound)
            receiveBuffer.removeSubrange(0..<newlineRange.upperBound)
            
            debugLogger.log("📦 Found message: \(messageData.count) bytes")
            
            if let json = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any],
               let type = json["type"] as? String {
                
                DispatchQueue.main.async { [weak self] in
                    self?.handleMessage(type: type, data: json)
                }
            } else {
                debugLogger.log("❌ Failed to parse JSON from message")
            }
        }
    }
    
    private func handleMessage(type: String, data: [String: Any]) {
        debugLogger.log("📥 Received message type: \(type)")
        
        switch type {
        case "settings":
            debugLogger.log("⚙️ Settings received: \(data)")
            // Update settings from server
            if data["resolution"] != nil {
                // Handle resolution update if needed
            }
            if let quality = data["quality"] as? Int {
                settings.quality = quality > 70 ? 3 : (quality > 40 ? 2 : 1)
            }
            
        case "frame":
            // Frame header received, read frame data
            if let dataSize = data["dataSize"] as? Int,
               let width = data["width"] as? Int,
               let height = data["height"] as? Int {
                debugLogger.log("🖼️ Frame header: \(width)x\(height), size: \(dataSize) bytes")
                receiveFrame(size: dataSize, width: width, height: height)
            } else {
                debugLogger.log("❌ Invalid frame header: \(data)")
            }
            
        default:
            debugLogger.log("❓ Unknown message type: \(type)")
            break
        }
    }
    
    private func receiveFrame(size: Int, width: Int, height: Int) {
        debugLogger.log("📥 Starting to receive frame: \(size) bytes")
        
        // Receive in chunks if needed - TCP may split large frames
        let frameData = Data()
        receiveFrameData(remaining: size, accumulated: frameData, width: width, height: height)
    }
    
    private func receiveFrameData(remaining: Int, accumulated: Data, width: Int, height: Int) {
        let chunkSize = min(remaining, 65536) // Read up to 64KB at a time
        
        connection?.receive(minimumIncompleteLength: 1, maximumLength: chunkSize) { [weak self] data, _, _, error in
            if let error = error {
                self?.debugLogger.log("❌ Frame chunk receive error: \(error)")
                DispatchQueue.main.async {
                    self?.errorMessage = "Frame receive error: \(error.localizedDescription)"
                }
                self?.receiveMessage()
                return
            }
            
            guard let data = data else {
                self?.debugLogger.log("❌ No data received")
                self?.receiveMessage()
                return
            }
            
            var newAccumulated = accumulated
            newAccumulated.append(data)
            let newRemaining = remaining - data.count
            
            self?.debugLogger.log("📦 Received chunk: \(data.count) bytes, remaining: \(newRemaining)")
            
            if newRemaining > 0 {
                // More data needed
                self?.receiveFrameData(remaining: newRemaining, accumulated: newAccumulated, width: width, height: height)
            } else {
                // Complete frame received
                self?.debugLogger.log("✅ Complete frame received: \(newAccumulated.count) bytes")
                
                // Decode image on background thread to prevent blocking
                DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                    if let image = UIImage(data: newAccumulated) {
                        DispatchQueue.main.async {
                            self?.currentFrame = image
                            self?.debugLogger.log("🖼️ Image decoded and displayed!")
                        }
                    } else {
                        self?.debugLogger.log("❌ Failed to decode image from \(newAccumulated.count) bytes")
                    }
                }
                
                // Continue receiving messages immediately without waiting for decode
                self?.receiveMessage()
            }
        }
    }
    
    func sendTouchEvent(location: CGPoint, type: String) {
        let touchData: [String: Any] = [
            "type": "touch",
            "eventType": type,
            "x": location.x,
            "y": location.y
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: touchData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            sendMessage(jsonString)
        }
    }
    
    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "AppSettings"),
           let decoded = try? JSONDecoder().decode(AppSettings.self, forKey: data) {
            settings = decoded
        }
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "AppSettings")
        }
    }
}

struct DeviceInfo: Identifiable {
    let id: String
    let name: String
    let ipAddress: String
    let connectionType: String
}

struct AppSettings: Codable {
    var autoConnect = true
    var keepScreenOn = true
    var orientation = "Auto"
    var showTouchIndicator = false
    var quality = 2 // 1=Low, 2=Medium, 3=High
}

extension JSONDecoder {
    func decode<T: Decodable>(_ type: T.Type, forKey data: Data) throws -> T {
        return try decode(type, from: data)
    }
}

