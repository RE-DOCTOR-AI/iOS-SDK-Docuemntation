//
//  DBHelper.swift
//  Vitals
//
//  Created by Artur Latypov on 3/31/24.
//  Copyright © 2024 Anurag Ajwani. All rights reserved.
//

import Foundation
import SQLite

class DBHelper {
    static func openConnection() -> Connection {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first!
        
        let sourcePath = "\(path)/db.sqlite3"
        
        _ = self.copyDatabaseIfNeeded(sourcePath: sourcePath)

        return try! Connection(sourcePath)
    }
    
    static private func copyDatabaseIfNeeded(sourcePath: String) -> Bool {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let destinationPath = documents + "/db.sqlite3"
        let exists = FileManager.default.fileExists(atPath: destinationPath)
        guard !exists else { return false }
        do {
            try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath)
            return true
        } catch {
          print("error during file copy: \(error)")
            return false
        }
    }
}
