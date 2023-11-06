import Foundation
//import Amplify
import AWSCore
import AWSFirehose

protocol LoggingProtocol {
    func info(message: String) -> Void
    func error(message: String) -> Void
}

let LOG_CACHE_SIZE = 200
/**
    Moved to kotlin shared library as LoggingService
 */
final class IOSLoggingService: LoggingProtocol {
    private var logQueue: [String] = []
    private var awsService: GatewayIntegrationProtocol
    
    static let shared = IOSLoggingService()

    private init() {
        let apiUrl = Bundle.main.infoDictionary?["TVSApiGateway"] as! String
        self.awsService = GatewayIntegrationService(api: apiUrl)
    }
    
    func info(message: String) {
        self.appendLogMessage(level: "info", message: message)
    }
    
    func error(message: String) {
        self.appendLogMessage(level: "error", message: message)
    }
    
    func flush() async {
        let sendTask = Task { () -> Void in
            await self.awsService.sendLogs(messages: self.logQueue)
            self.logQueue.removeAll()
        }
    }
    
    private func logsToString() -> String {
        self.logQueue.joined(separator: "\n")
    }
    
    private func appendLogMessage(level: String, message: String) {
        let timestamp = self.getCurrentUtcTimestamp()
        self.logQueue.append("\(timestamp) [\(level)]: \(message)")
        
        if (logQueue.count > LOG_CACHE_SIZE) {
            self.logQueue.removeFirst()
        }
    }
    
    private func getCurrentUtcTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: Date())
    }
}
