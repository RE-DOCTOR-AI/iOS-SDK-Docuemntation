import Foundation
import shared

/**
    This is a dummy class implementing UserParametersProvider interface.
    The class serves as the source of user parameters used for computing vitals and risks
 */

class IosProvider: UserParametersProvider {    
    func getUserParameters() -> User? {        
        return UserParameters(height: 180.0, weight: 75.0, age: 39, gen: 1)
    }
}
