import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @State private var showSettings = false
    @State private var showDebugConsole = false
    
    var body: some View {
        ZStack {
            if connectionManager.isConnected {
                // Display screen content
                ScreenDisplayView()
                    .edgesIgnoringSafeArea(.all)
            } else {
                // Connection screen
                ConnectionView()
            }
            
            // Settings and Debug buttons overlay - ALWAYS ACCESSIBLE
            VStack {
                HStack {
                    // Cancel button during connection
                    if connectionManager.isConnecting {
                        Button(action: {
                            connectionManager.disconnect()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(25)
                            .shadow(radius: 5)
                        }
                        .padding(.leading, 20)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 10) {
                        // Debug console - ALWAYS visible and working
                        Button(action: {
                            showDebugConsole = true
                        }) {
                            Image(systemName: "terminal")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        
                        if !connectionManager.isConnected && !connectionManager.isConnecting {
                            Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue.opacity(0.9))
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            .zIndex(1000) // Ensure buttons are on top
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(connectionManager)
        }
        .fullScreenCover(isPresented: $showDebugConsole) {
            DebugConsoleView(isPresented: $showDebugConsole)
                .environmentObject(connectionManager)
        }
    }
}

struct ConnectionView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @State private var manualIP: String = ""
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Image(systemName: "display.2")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text("Secondary Screen")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Connect to your Windows PC")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                
                // Instructions box
                VStack(alignment: .leading, spacing: 8) {
                    Text("📋 How to Connect:")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("1. Start the Windows app")
                    Text("2. Click 'Start Server'")
                    Text("3. Enter the IP shown below")
                    Text("4. Tap 'Connect'")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
                .padding(.horizontal, 40)
                .padding(.top, 10)
                
                if connectionManager.isSearching {
                    VStack(spacing: 15) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Searching for devices...")
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                } else if !connectionManager.availableDevices.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Available Devices")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(connectionManager.availableDevices, id: \.id) { device in
                            Button(action: {
                                connectionManager.connectToDevice(device)
                            }) {
                                HStack {
                                    Image(systemName: "desktopcomputer")
                                    VStack(alignment: .leading) {
                                        Text(device.name)
                                            .font(.headline)
                                        Text(device.ipAddress)
                                            .font(.caption)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
                
                // Manual connection
                VStack(spacing: 15) {
                    Text("Enter your PC's IP address:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    TextField("192.168.0.112", text: $manualIP)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 300)
                        .autocapitalization(.none)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 18, weight: .medium))
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            connectionManager.startSearching()
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Auto Search")
                            }
                            .frame(width: 140, height: 50)
                            .background(Color.white.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(25)
                        }
                        
                        Button(action: {
                            if !manualIP.isEmpty {
                                connectionManager.connectManually(to: manualIP)
                            }
                        }) {
                            HStack {
                                Image(systemName: "link")
                                Text("Connect")
                            }
                            .frame(width: 140, height: 50)
                            .background(manualIP.isEmpty ? Color.gray : Color.white)
                            .foregroundColor(manualIP.isEmpty ? .white.opacity(0.5) : .blue)
                            .cornerRadius(25)
                        }
                        .disabled(manualIP.isEmpty)
                    }
                }
                .padding(.top, 30)
                
                // Connection status/error messages
                if connectionManager.isConnecting {
                    HStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Connecting...")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.top, 20)
                } else if let error = connectionManager.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                }
            }
            .padding()
        }
    }
}

struct ScreenDisplayView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @State private var showDisconnectButton = true
    @State private var hideButtonTimer: Timer?
    @State private var showDebugConsole = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let image = connectionManager.currentFrame {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
            } else {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                    Text("Waiting for screen data...")
                        .foregroundColor(.white)
                        .padding(.top, 20)
                }
            }
            
            // Disconnect and Debug Console buttons - ALWAYS VISIBLE when waiting for data
            if showDisconnectButton || connectionManager.currentFrame == nil {
                VStack {
                    HStack {
                        Button(action: {
                            connectionManager.disconnect()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Debug console button - always visible when waiting
                        Button(action: {
                            showDebugConsole = true
                        }) {
                            Image(systemName: "terminal")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .onTapGesture {
            withAnimation {
                showDisconnectButton.toggle()
            }
            resetHideTimer()
        }
        .onAppear {
            resetHideTimer()
        }
        .fullScreenCover(isPresented: $showDebugConsole) {
            DebugConsoleView(isPresented: $showDebugConsole)
                .environmentObject(connectionManager)
        }
    }
    
    private func resetHideTimer() {
        hideButtonTimer?.invalidate()
        showDisconnectButton = true
        hideButtonTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation {
                showDisconnectButton = false
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Connection")) {
                    Toggle("Auto-connect on Launch", isOn: $connectionManager.settings.autoConnect)
                    Toggle("Keep Screen On", isOn: $connectionManager.settings.keepScreenOn)
                }
                
                Section(header: Text("Display")) {
                    Picker("Orientation", selection: $connectionManager.settings.orientation) {
                        Text("Auto").tag("Auto")
                        Text("Landscape").tag("Landscape")
                        Text("Portrait").tag("Portrait")
                    }
                    
                    Toggle("Show Touch Indicator", isOn: $connectionManager.settings.showTouchIndicator)
                }
                
                Section(header: Text("Performance")) {
                    Picker("Quality", selection: $connectionManager.settings.quality) {
                        Text("Low").tag(1)
                        Text("Medium").tag(2)
                        Text("High").tag(3)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Device ID")
                        Spacer()
                        Text(connectionManager.deviceId.prefix(8) + "...")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                connectionManager.saveSettings()
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
