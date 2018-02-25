//
//  FirstViewController.swift
//  way
//
//  Created by Müge Kural on 10/02/2018.
//  Copyright © 2018 Myth. All rights reserved.
//

import UIKit
import HealthKit

class FirstViewController: UIViewController {
   
    private let authorizeHealthKitSection = 2
    let healthKitStore: HKHealthStore = HKHealthStore()
    @IBOutlet weak var authSwitch: UISwitch!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var heartRateLabel: UILabel!
    
    private let userHealthProfile = UserHealthProfile()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //*******************************************
    //Health Kit Functions
    
    private func authorizeHealthKit() {
        HealthKitSetupAssistant.authorizeHealthKit {(authorized, error) in
            guard authorized else {
                let baseMessage = "HealthKit authorization failed."
                
                if let error = error {
                    print("\(baseMessage). Reason: \(error.localizedDescription)")
                }else {
                    print(baseMessage)
                }
                return
            }
            
            print("HealthKit Successfuly Authorized.")
        }
    }

    private func loadAndDisplayHeartRate() {
        //1. Use HealthKit to create the HeartRate Sample Type
        guard let heartRateSampleType = HKSampleType.quantityType(forIdentifier: .heartRate) else {
            print ("HeartRate Sample Type (Body Mass) is no longer available for HealthKit")
            return
        }
        
        ProfileDataStore.getAVGHeartRate(for: heartRateSampleType) { (sample, error) in
            //2. Convert the weight sample to kilos, save to the profile model,
            //   and update the user interface.
            let heartRateInCount = sample
            self.userHealthProfile.heartRate = heartRateInCount
            print(heartRateInCount)
            
            if let heartRate = self.userHealthProfile.heartRate {
                self.heartRateLabel.text = "Your heart rate: " + heartRate.description
            }
        }
    }
    
    @IBAction func authSwitchToggled(_ sender: UISwitch) {
        changeSwitchText()
    }
    
    func changeSwitchText() {
        if authSwitch.isOn {
            label.text = "Switch is on"
            authorizeHealthKit()
            loadAndDisplayHeartRate()
        } else {
            label.text = "Switch is off"
        }
    }
    




}

