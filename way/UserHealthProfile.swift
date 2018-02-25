//
//  UserHealthProfile.swift
//  way
//
//  Created by Müge Kural on 18.02.2018.
//  Copyright © 2018 Myth. All rights reserved.
//

import HealthKit

class UserHealthProfile {
    
    // For now only the heart rate value is used (fatihcim)
    
    var age: Int?
    var biologicalSex: HKBiologicalSex?
    var bloodType: HKBloodType?
    var heightInMeters: Double?
    var weightInKilograms: Double?
    var heartRate: Double?
    
    var bodyMassIndex: Double? {
        
        guard let weightInKilograms = weightInKilograms,
            let heightInMeters = heightInMeters,
            heightInMeters > 0 else {
                return nil
        }
        return (weightInKilograms/(heightInMeters*heightInMeters))
    }
    
    
}
