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
        
        var typeHeart = HKQuantityType.quantityType(forIdentifier: .heartRate)
        var startDate = Date() - 7 * 24 * 60 * 60 // start date is a week
        var predicate: NSPredicate? = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: HKQueryOptions.strictEndDate)
        
        var squery = HKStatisticsQuery(quantityType: typeHeart!, quantitySamplePredicate: predicate, options: .discreteAverage, completionHandler: {(query: HKStatisticsQuery,result: HKStatistics?, error: Error?) -> Void in
            DispatchQueue.main.async(execute: {() -> Void in
                var quantity: HKQuantity? = result?.averageQuantity()
                var beats: Double? = quantity?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                //  print("got: \(String(format: "%.f", beats!))")
                
                completion(beats, nil)
            })
        })
        HKHealthStore().execute(squery)
    }
    
    
}
