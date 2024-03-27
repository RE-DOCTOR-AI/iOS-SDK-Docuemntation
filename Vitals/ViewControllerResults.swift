//
//  ViewControllerResults.swift
//  Vitals
//
//  Created by Artur Latypov on 3/9/24.
//  Copyright © 2024 Anurag Ajwani. All rights reserved.
//

import Foundation
import UIKit
import shared

class ViewControllerResults: UIViewController{
    @IBOutlet var SpO2: UILabel!
    @IBOutlet var Respiration: UILabel!
    @IBOutlet var HeartRate: UILabel!
    @IBOutlet var BloodPressure: UILabel!
    @IBOutlet var riskLevel: UILabel!
    @IBOutlet var pulsePressure: UILabel!
    @IBOutlet var stress: UILabel!
    @IBOutlet var reflectionIndex: UILabel!
    @IBOutlet var hrv: UILabel!
    @IBOutlet var lasi: UILabel!
    @IBOutlet var Glucose: UILabel!
    @IBOutlet var StartAgain: UIButton!
    @IBOutlet var CollectData: UIButton!

    var existingPatientResponse: [User_] = []
    var existingPatient: User_?
    var newPatient: CreatedUser?
    var glucoseLevelProcessor: GlucoseLevelProcessorIOS?
    let keychain = KeychainSwift()
    var animationTimer: Timer?
    
    override func viewDidLoad()
    {
        SpO2.text = Singleton.sharedInstance.SpO2
        Respiration.text = Singleton.sharedInstance.Respiration == "0" ? "N/A" : Singleton.sharedInstance.Respiration
        HeartRate.text = Singleton.sharedInstance.HeartRate == "0" ? "N/A" : Singleton.sharedInstance.HeartRate
        BloodPressure.text = Singleton.sharedInstance.BloodPressure
        riskLevel.text = Singleton.sharedInstance.riskLevel
        pulsePressure.text = Singleton.sharedInstance.pulsePressure
        hrv.text = Singleton.sharedInstance.hrv
        lasi.text = Singleton.sharedInstance.lasi
        stress.text = Singleton.sharedInstance.stress
        reflectionIndex.text = Singleton.sharedInstance.reflectionIndex
        StartAgain.isEnabled = false
        CollectData.isEnabled = false

        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextViewController = segue.destination as? ViewControllerCollectData {
            nextViewController.glucoseLevelProcessor = glucoseLevelProcessor
        }
    }
    
    func animateProgress() {
        let text = "Processing"
        var dotCount = 0
        
        self.Glucose.textAlignment = NSTextAlignment.left
        
        DispatchQueue.main.async {
            self.animationTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) {_ in
                dotCount += 1
                let dots = String(repeating: ".", count: dotCount % 4)
                self.Glucose.text = "\(text)\(dots)"
            }
        }
        self.animationTimer?.fire()
        self.Glucose.textColor = UIColor.systemBlue
    }
    
    func stopAnimateProgress() {
        self.Glucose.textAlignment = NSTextAlignment.right
        self.animationTimer?.invalidate()
    }
}
