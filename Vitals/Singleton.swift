//
//  Singleton.swift
//  Vitals
//
//  Created by Artur Latypov on 3/9/24.
//  Copyright © 2024 Anurag Ajwani. All rights reserved.
//

import Foundation
import shared

//so tht we can share the data between app views (screens) and view controllers
class Singleton {
    let frameConsumer = DefaultFrameConsumerIOS()
    let vitalSignProcessor = VitalSignProcessorIOS()
    let glucoseProcessor = GlucoseLevelProcessorIOS()
    
    var patientHeight : Double = 0.0
    var patientWeight : Double = 0.0
    var patientAge : String = "0"
    var patientGender : Int32 = 0
    
    var SpO2: String = "0.00"
    var glucose: String = "0.00"
    var glucoseMean: Int32 = 0
    var Respiration: String = "0.00"
    var HeartRate: String = "0.00"
    var BloodPressure: String = "0.00"
    var SBP : String = "0"
    var DBP : String = "0"
    var riskLevel : String = "UNKNOWN"
    var pulsePressure: String = "0.00"
    var stress: String = "0.00"
    var reflectionIndex: String = "0.00"
    var hrv: String = "0.00"
    var lasi: String = "0.00"
    
    static let sharedInstance = Singleton()
    
    private init(){}
}
