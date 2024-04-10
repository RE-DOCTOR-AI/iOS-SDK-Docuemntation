//
//  ViewControllerCollectData.swift
//  Vitals
//
//  Created by Artur Latypov on 3/9/24.
//  Copyright © 2024 Anurag Ajwani. All rights reserved.
//
import UIKit
import Foundation
import shared

class ViewControllerCollectData: UIViewController {
    @IBOutlet var bloodOxygen: UILabel!
    @IBOutlet var heartRate: UILabel!
    @IBOutlet var respirationRate: UILabel!
    @IBOutlet var glucoseLevels: UILabel!
    @IBOutlet var bloodOxygenField: UITextField!
    @IBOutlet var heartRateField: UITextField!
    @IBOutlet var respirationRateField: UITextField!
    @IBOutlet var glucoseLevelsField: UITextField!
    @IBOutlet var bloodPressureField: UITextField!
    @IBOutlet var commentField: UITextField!
    @IBOutlet var collectDataButton: UIButton!
    
    @IBAction func collectDataButtonTap(sender: UIButton) {
        let isCollected = collectData()

        if (isCollected) {
            sender.setTitle("Success", for: UIControl.State.normal)
            sender.isEnabled = false
        }
    }
            
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        bloodOxygen.text = Singleton.sharedInstance.SpO2
        heartRate.text = Singleton.sharedInstance.HeartRate == "0.00" ? "N/A" : Singleton.sharedInstance.HeartRate
        respirationRate.text = Singleton.sharedInstance.Respiration == "0.00" ? "N/A" : Singleton.sharedInstance.Respiration
        glucoseLevels.text = Singleton.sharedInstance.glucose
    }

    private func collectData() -> Bool {
        let rawData = Singleton.sharedInstance.frameConsumer.getGlucoseFrameData()
        let vitalSignProcessor = Singleton.sharedInstance.vitalSignProcessor
        let glucoseLevelProcessor = Singleton.sharedInstance.glucoseProcessor
        
        let inferredResults = VitalsDto(
            bps: getIntOrMinusOne(from: vitalSignProcessor.getSPValue()),
            bpd: getIntOrMinusOne(from: vitalSignProcessor.getDPValue()),
            pulse: getIntOrMinusOne(from: vitalSignProcessor.getBeatsValue()),
            respiration: getIntOrMinusOne(from: vitalSignProcessor.getBreathValue()),
            oxygen: getIntOrMinusOne(from: vitalSignProcessor.getSPo2Value()),
            glucoseMin: glucoseLevelProcessor.getGlucoseMinValue(),
            glucoseMax: glucoseLevelProcessor.getGlucoseMaxValue()
        )
        let realVitals = getRealVitals()
        let user = VitalsScannerSDK.shared.user
        
        print("Attempting to collect data: \n \(rawData) \n \(inferredResults) \n \(realVitals) \n \(user)")
        
        return VitalsScannerSDK.shared.logs.addDataCollectionLog(
            framesData: Singleton.sharedInstance.frameConsumer.getGlucoseFrameData(),
            predicted: inferredResults,
            real: realVitals,
            user: user,
            comment: commentField.text ?? ""
        )
    }
    
    private func getIntOrMinusOne(from text: String) -> Int32 {
        Int32(text) ?? -1
    }
    
    func parseBloodPressure(from reading: String) -> (systolic: Int32, diastolic: Int32) {
        let components = reading.split(separator: "/")
        guard components.count == 2,
              let systolic = Int32(components[0]),
              let diastolic = Int32(components[1]) else {
            return (-1, -1) // Default values in case of parsing error
        }
        return (systolic, diastolic)
    }
    
    private func getRealVitals() -> VitalsDto {
        guard
            let glucoseText = glucoseLevelsField.text,
            let heartText = heartRateField.text,
            let bloodText = bloodOxygenField.text,
            let respirationText = respirationRateField.text,
            let bloodPressureText = bloodPressureField.text
        else { return VitalsDto(
            bps: -1,
            bpd: -1,
            pulse: -1,
            respiration: -1,
            oxygen: -1,
            glucoseMin: -1,
            glucoseMax: -1
        )}
        
        let realGlucose = getIntOrMinusOne(from: glucoseText)
        let realPulse = getIntOrMinusOne(from: heartText)
        let realOxygen = getIntOrMinusOne(from: bloodText)
        let realRespiration = getIntOrMinusOne(from: respirationText)
        let parsedBloodPressure = parseBloodPressure(from: bloodPressureText)
        
        return VitalsDto(
            bps: parsedBloodPressure.systolic,
            bpd: parsedBloodPressure.diastolic,
            pulse: realPulse,
            respiration: realRespiration,
            oxygen: realOxygen,
            glucoseMin: realGlucose,
            glucoseMax: realGlucose
        )
    }
}
