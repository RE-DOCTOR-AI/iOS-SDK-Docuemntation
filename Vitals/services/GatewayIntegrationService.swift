//
//  GatewayIntegrationService.swift
//  Vitals
//
//  Created by Artur Latypov on 12/11/22.
//  Copyright © 2022 Anurag Ajwani. All rights reserved.
//

import Foundation
import AWSCore


enum SimpleAWSRequestError: Error {
    case defaultConfigurationNotFound
    case configurationInitFailed
    case payloadGenerationFailed
}

protocol GatewayIntegrationProtocol {
    func sendLogs(messages: [String]) async -> Void
}

struct JSONPayload: Encodable {
    let records: [String]
}


final class GatewayIntegrationService: GatewayIntegrationProtocol {
    let apiUrl: String
    
    init(api: String) {
        self.apiUrl = api
    }
    
    func sendLogs(messages: [String]) async -> Void {
        if (messages.isEmpty) {
            print("Message list is empty. Skipping")
        }
        do {
            let payload = JSONPayload(records: messages)
            let json = try JSONEncoder().encode(payload)
            let logApiUrl = URL(string: self.apiUrl)!
            var request = URLRequest(url: logApiUrl)
            request.httpMethod = "PUT"
            request.httpBody = json
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    return
                }
                
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    print(responseJSON)
                }
            }
            task.resume()
        } catch {
            print("Could not serialize json")
        }
    }
    
    private func getLogsPayload(messages: [String]) throws -> Data {
        let data = try JSONSerialization.data(withJSONObject: ["records", messages])
        return data
    }
}

