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
    
    class func getMostRecentSample(for sampleType: HKSampleType,
                                   completion: @escaping (HKQuantitySample?, Error?) -> Swift.Void) {
        
        //1. Use HKQuery to load the most recent samples.
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                              end: Date(),
                                                              options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: false)
        let limit = 1
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: mostRecentPredicate,
                                        limit: limit,
                                        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                                            
                                            //2. Always dispatch to the main thread when complete.
                                            DispatchQueue.main.async {
                                                guard let samples = samples,
                                                    let mostRecentSample = samples.first as? HKQuantitySample else {
                                                        
                                                        completion(nil, error)
                                                        return
                                                }
                                                completion(mostRecentSample, nil)
                                            }
        }
        HKHealthStore().execute(sampleQuery)
    }
    
}
