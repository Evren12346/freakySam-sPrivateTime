import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.08, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HeaderView()
                    .padding(.bottom, 20)
                
                TabView(selection: $selectedTab) {
                    // Dashboard Tab
                    DashboardTab()
                        .tabItem {
                            Label("Dashboard", systemImage: "gauge.open.right")
                        }
                        .tag(0)
                    
                    // Controls Tab
                    ControlsTab()
                        .tabItem {
                            Label("Controls", systemImage: "switch.2")
                        }
                        .tag(1)
                    
                    // Status Tab
                    StatusTab()
                        .tabItem {
                            Label("Status", systemImage: "info.circle")
                        }
                        .tag(2)
                }
                .frame(maxHeight: .infinity)
            }
            .padding()
        }
    }
}

struct HeaderView: View {
    @EnvironmentObject var appManager: AppManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MacBook Anonymizer")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    
                    Text("macOS Tor Anonymity Helper")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                StatusIndicator(isActive: appManager.isRunning)
            }
            
            HStack {
                Circle()
                    .fill(appManager.statusColor)
                    .frame(width: 12, height: 12)
                
                Text(appManager.status)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .foregroundColor(appManager.statusColor)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct StatusIndicator: View {
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 16, height: 16)
                .shadow(color: (isActive ? Color.green : Color.red).opacity(0.5), radius: 4)
            
            Text(isActive ? "ON" : "OFF")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct DashboardTab: View {
    @EnvironmentObject var appManager: AppManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Main control card
                VStack(spacing: 20) {
                    if appManager.isLoading {
                        ProgressView()
                            .tint(.cyan)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            appManager.start()
                        }) {
                            HStack {
                                Image(systemName: "power.circle.fill")
                                Text("Start Tor")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            appManager.stop()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("Stop Tor")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quick Status")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(appManager.isRunning ? "Tor Active" : "Tor Inactive")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            appManager.checkStatus()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.cyan)
                                .padding(8)
                                .background(Color.cyan.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Quick actions
                VStack(spacing: 10) {
                    Text("Quick Actions")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 8) {
                        QuickActionButton(
                            title: "Run Diagnostics",
                            description: "Check system configuration",
                            icon: "stethoscope",
                            action: { appManager.doctor() }
                        )
                        
                        QuickActionButton(
                            title: "Test Tor Connection",
                            description: "Verify Tor is routing correctly",
                            icon: "network",
                            action: { appManager.test() }
                        )
                        
                        QuickActionButton(
                            title: "Privacy Report",
                            description: "Review potential privacy leaks",
                            icon: "lock.slash",
                            action: { appManager.privacyReport() }
                        )
                    }
                }
                
                Spacer()
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text(description)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
            )
        }
    }
}

struct ControlsTab: View {
    @EnvironmentObject var appManager: AppManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ControlCard(
                    title: "Start Tor",
                    description: "Enable Tor routing and anonymity features",
                    icon: "power.circle.fill",
                    color: Color.green,
                    action: { appManager.start() }
                )
                
                ControlCard(
                    title: "Stop Tor",
                    description: "Disable Tor and restore normal network settings",
                    icon: "stop.circle.fill",
                    color: Color.red,
                    action: { appManager.stop() }
                )
                
                ControlCard(
                    title: "Panic Stop",
                    description: "Emergency fast rollback of all proxy changes",
                    icon: "exclamationmark.triangle.fill",
                    color: Color.orange,
                    action: { appManager.panicStop() }
                )
                
                ControlCard(
                    title: "Run Full Self-Test",
                    description: "Complete verification and rollback test",
                    icon: "checkmark.circle.fill",
                    color: Color.blue,
                    action: { appManager.selfTest() }
                )
                
                Spacer()
            }
        }
    }
}

struct ControlCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(description)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct StatusTab: View {
    @EnvironmentObject var appManager: AppManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Output Log")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ScrollView {
                        Text(appManager.output.isEmpty ? "No output yet. Run a command to see output here." : appManager.output)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .background(Color(red: 0.05, green: 0.05, blue: 0.08))
                            .cornerRadius(8)
                    }
                    .frame(minHeight: 200)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                )
                
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppManager())
}
