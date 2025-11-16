import SwiftUI

struct DebugConsoleView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Debug console
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(connectionManager.debugLogger.logs)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .id("bottom")
                        }
                        .onChange(of: connectionManager.debugLogger.logs) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Control buttons
                HStack(spacing: 15) {
                    Button(action: {
                        connectionManager.debugLogger.clear()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        UIPasteboard.general.string = connectionManager.debugLogger.logs
                    }) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                            Text("Copy")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
            }
            .navigationTitle("Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Close")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                },
                trailing: Button(action: {
                    isPresented = false
                }) {
                    Text("Done")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
