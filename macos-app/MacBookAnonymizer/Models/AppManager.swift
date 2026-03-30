import Foundation
import Combine

class AppManager: NSObject, ObservableObject {
    @Published var isRunning = false
    @Published var status = "Initializing..."
    @Published var statusColor = Color.gray
    @Published var lastIP: String?
    @Published var torIP: String?
    @Published var output = ""
    @Published var isLoading = false
    
    private let scriptPath: String
    
    override init() {
        // Find the script relative to the app bundle
        if let bundlePath = Bundle.main.bundlePath as String? {
            let pathComponents = bundlePath.components(separatedBy: "/")
            if let appIdx = pathComponents.lastIndex(of: "MacBookAnonymizer.app") {
                let basePath = pathComponents[0...appIdx-1].joined(separator: "/")
                self.scriptPath = "\(basePath)/bin/macbook_anonymizer.sh"
            } else {
                // Fallback for development
                self.scriptPath = "\(NSHomeDirectory())/Applications/MacBook Anonymizer/bin/macbook_anonymizer.sh"
            }
        } else {
            self.scriptPath = "\(NSHomeDirectory())/Applications/MacBook Anonymizer/bin/macbook_anonymizer.sh"
        }
        
        super.init()
        checkStatus()
    }
    
    func start() {
        executeCommand(["start"])
    }
    
    func stop() {
        executeCommand(["stop"])
    }
    
    func panicStop() {
        executeCommand(["panic-stop"])
    }
    
    func test() {
        executeCommand(["test"])
    }
    
    func doctor() {
        executeCommand(["doctor"])
    }
    
    func privacyReport() {
        executeCommand(["privacy-report"])
    }
    
    func checkStatus() {
        executeCommand(["status"])
    }
    
    func selfTest() {
        executeCommand(["self-test"])
    }
    
    private func executeCommand(_ args: [String]) {
        isLoading = true
        output = "Running command: \(args.joined(separator: " "))...\n"
        
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            // Build command - use sudo if needed
            let cmd = "cd '\(NSHomeDirectory())/Applications/MacBook Anonymizer' && './bin/macbook_anonymizer.sh' \(args.joined(separator: " "))"
            process.arguments = ["-c", cmd]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.output = output
                        self.isLoading = false
                        self.updateStatusFromOutput(output)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.output = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func updateStatusFromOutput(_ output: String) {
        if output.lowercased().contains("running") || output.lowercased().contains("active") {
            isRunning = true
            status = "Tor is active"
            statusColor = Color.green
        } else if output.lowercased().contains("stopped") || output.lowercased().contains("inactive") {
            isRunning = false
            status = "Tor is stopped"
            statusColor = Color.red
        } else {
            status = "Status unknown"
            statusColor = Color.gray
        }
    }
}
