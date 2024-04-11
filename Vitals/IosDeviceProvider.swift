//
//  IosDeviceProvider.swift
//  Vitals
//
//  Created by Artur Latypov on 8/28/23.
//  Copyright © 2023 Anurag Ajwani. All rights reserved.
//

import Foundation
import shared

class IosProvider: UserParametersProvider {
    init() {
        Patient.initializeDB()
    }
    
    func getUserParameters() -> User? {
        let user = Patient.load()
        
        user.setIsImperial(false) // User parameters should be in SI units
        
        print("Returning user \(user.toString())")
        
        return UserParameters(
            height: user.patientHeight,
            weight: user.patientWeight,
            age: Int32(user.getAge()),
            gen: Int32(user.gender)
        )
    }
}
