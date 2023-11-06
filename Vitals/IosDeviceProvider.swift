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
    func getUserParameters() -> User? {        
        return UserParameters(height: 180.0, weight: 75.0, age: 39, gen: 1)
    }
}
