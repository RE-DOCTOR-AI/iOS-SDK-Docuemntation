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
    let keychain = KeychainSwift()
    var animationTimer: Timer?
    
    override func viewDidLoad() {
        StartAgain.isEnabled = false
        CollectData.isEnabled = false
        
        if (!Singleton.sharedInstance.dataProcessed) {
            self.animateProgress()
            self.calculateVitals()
            self.calculateGlucose()
        } else {
            self.presentVitals()
            self.presentGlucose()
        }
        super.viewDidLoad()
    }
    
    private func calculateVitals() -> Void {
        DispatchQueue.global().async {
            let vitalSignProcessor = Singleton.sharedInstance.vitalSignProcessor
            Singleton.sharedInstance.vitalSignProcessor.process(framesData: Singleton.sharedInstance.frameConsumer.getVitalsFramesData())
            
            // Putting values to Singleton to show them on viewController
            Singleton.sharedInstance.SpO2 = vitalSignProcessor.getSPo2Value()
            Singleton.sharedInstance.Respiration = vitalSignProcessor.getBreathValue()
            Singleton.sharedInstance.HeartRate = (Int(vitalSignProcessor.getBeatsValue()) ?? 0) == 0 ? "0" : String((Int(vitalSignProcessor.getBeatsValue()) ?? 0))
            Singleton.sharedInstance.BloodPressure = "\(vitalSignProcessor.getSPValue())/\(vitalSignProcessor.getDPValue())"
            Singleton.sharedInstance.SBP = vitalSignProcessor.getSPValue()
            Singleton.sharedInstance.DBP = vitalSignProcessor.getDPValue()
            Singleton.sharedInstance.lasi = vitalSignProcessor.getLasiValue()
            Singleton.sharedInstance.reflectionIndex = vitalSignProcessor.getReflectionIndexValue()
            Singleton.sharedInstance.pulsePressure = vitalSignProcessor.getPulsePressureValue()
            Singleton.sharedInstance.stress = vitalSignProcessor.getStressValue()
            Singleton.sharedInstance.hrv = vitalSignProcessor.getHrvValue()
            
            DispatchQueue.main.sync {
                self.presentVitals()
            }
        }
    }
    

    private func calculateGlucose() -> Void {
        DispatchQueue.global().async {
            // Start processing
            let vitalSignProcessor = Singleton.sharedInstance.vitalSignProcessor
            let glucoseLevelProcessor = Singleton.sharedInstance.glucoseProcessor
            glucoseLevelProcessor.process(framesData: Singleton.sharedInstance.frameConsumer.getGlucoseFrameData())
            
            let glucoseMin = glucoseLevelProcessor.getGlucoseMinValue()
            let glucoseMax = glucoseLevelProcessor.getGlucoseMaxValue()
            let glucoseMean = (glucoseMin + glucoseMax) / 2
            let risk = vitalSignProcessor.getRiskLevelValue()
            var riskLevel = RiskLevel.unknown

            if (risk != nil) {
                let riskLevelValue = VitalsRiskLevelIOSKt.getVitalsWithGlucose(vitalsRiskLevel: risk!, glucose: Double(glucoseMean))
                riskLevel = VitalsRiskLevelKt.getRiskLevel(riskGrades: riskLevelValue)
            }
            
            Singleton.sharedInstance.glucose = "[\(glucoseMin) - \(glucoseMax)]"
            Singleton.sharedInstance.glucoseMean = glucoseMean
            Singleton.sharedInstance.riskLevel = riskLevel.name
            Singleton.sharedInstance.dataProcessed = true
            
            DispatchQueue.main.sync {
                self.stopAnimateProgress()
                self.presentGlucose()
            }
        }
    }
    
    private func presentVitals() {
        // Showing results in main thread
        self.SpO2.text = Singleton.sharedInstance.SpO2
        self.Respiration.text = Singleton.sharedInstance.Respiration == "0" ? "N/A" : Singleton.sharedInstance.Respiration
        self.HeartRate.text = Singleton.sharedInstance.HeartRate == "0" ? "N/A" : Singleton.sharedInstance.HeartRate
        self.BloodPressure.text = Singleton.sharedInstance.BloodPressure
        self.riskLevel.text = Singleton.sharedInstance.riskLevel
        self.pulsePressure.text = Singleton.sharedInstance.pulsePressure
        self.hrv.text = Singleton.sharedInstance.hrv
        self.lasi.text = Singleton.sharedInstance.lasi
        self.stress.text = Singleton.sharedInstance.stress
        self.reflectionIndex.text = Singleton.sharedInstance.reflectionIndex
    }
    
    
    private func presentGlucose() {
        // Showing result in main thread
        self.Glucose.textColor = UIColor.label
        self.Glucose.textAlignment = NSTextAlignment.right
        self.Glucose.text = Singleton.sharedInstance.glucose
        self.riskLevel.text = Singleton.sharedInstance.riskLevel
        self.StartAgain.isEnabled = true
        self.CollectData.isEnabled = true
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
