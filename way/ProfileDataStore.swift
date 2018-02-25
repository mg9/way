//
//  ProfileDataStore.swift
//  way
//
//  Created by Müge Kural on 18.02.2018.
//  Copyright © 2018 Myth. All rights reserved.
//

import HealthKit

class ProfileDataStore {
    
    class func getAVGHeartRate(for sampleType: HKSampleType,
                               completion: @escaping (Double?, Error?) -> Swift.Void) {

        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let sortByTime = NSSortDescriptor(key:HKSampleSortIdentifierEndDate, ascending:false)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm:ss"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YYYY"
        
        let query = HKSampleQuery(sampleType:heartRateType, predicate:nil, limit:600, sortDescriptors:[sortByTime], resultsHandler:{(query, results, error) in
            guard let results = results else { return }
            
            //consider only the first result (result includes more than one value)
            let quantity = (results.first as! HKQuantitySample).quantity
            let heartRateUnit = HKUnit(from: "count/min")
            quantity.doubleValue(for: heartRateUnit)
            completion(quantity.doubleValue(for: heartRateUnit), nil)
            
        })
        HKHealthStore().execute(query)
        
    }
    
    
}
