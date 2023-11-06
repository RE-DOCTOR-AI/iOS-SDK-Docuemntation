//
//  AppDelegate.swift
//  ProcessingCameraFeed
//
//  Created by Anurag Ajwani on 02/05/2020.
//  Copyright © 2020 Anurag Ajwani. All rights reserved.
//

import UIKit
import shared


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        do {
            //This is to provide SDK with User data
            let client = IosProvider()
            
            //SDK Initialization
            try VitalsScannerSDK.shared.doInitScanner(
                licenseKey: "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJjdXN0b21lck5hbWUiOiJSZURvY3RvciIsInZhbGlkaXR5RGF0ZSI6IjIwMjUtMTItMzEiLCJhcGlLZXkiOiJuNTcyRjNvZkliOUxsdlYwa2hrYm81RlFuQUZvVmtXaDVNck1CYlhhIiwibGljZW5zZVR5cGUiOiJkZXZlbG9wIn0.GH2-RJKO-PebVtz3aypmqF9mcvPay5Q_jSW_NSAMn0zgMIRwzN7bnnCEaQsJVkwsOt5SbFv48Hk-HyCv0RtSoQ",
                userParametersProvider: client
            )
        } catch {
            print("InitScanner failed")
            return false
        }

        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

