//
//  FirstViewController.swift
//  way
//
//  Created by Müge Kural on 10/02/2018.
//  Copyright © 2018 Myth. All rights reserved.
//

import UIKit
import HealthKit
import CocoaMQTT
import CoreLocation

class FirstViewController: UIViewController, CLLocationManagerDelegate {
    
    private let authorizeHealthKitSection = 2
    let healthKitStore: HKHealthStore = HKHealthStore()
    @IBOutlet weak var authSwitch: UISwitch!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var heartRateLabel: UILabel!
    
    private let userHealthProfile = UserHealthProfile()
   
    var mqtt: CocoaMQTT?
    var animal: String?
    var timer:Timer?
    var message: String?
    var lat: CLLocationDegrees?
    var lon: CLLocationDegrees?
    let defaultHost = "iot.eteration.com"
    var deviceId = UIDevice.current.identifierForVendor!.uuidString
    var deviceName = UIDevice.current.name
    var locationManager: CLLocationManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            
        }

        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func mqttSetting() {
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        mqtt = CocoaMQTT(clientID: clientID, host: defaultHost, port: 1883)
        mqtt!.username = ""
        mqtt!.password = ""
        mqtt!.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
        mqtt!.keepAlive = 60
        mqtt!.delegate = self
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
    
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        lat = userLocation.coordinate.latitude
        print("user longitude = \(userLocation.coordinate.longitude)")
        lon=userLocation.coordinate.longitude
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }

    
    @objc private func loadAndDisplayHeartRate() {
        //1. Use HealthKit to create the HeartRate Sample Type
        guard let heartRateSampleType = HKSampleType.quantityType(forIdentifier: .heartRate) else {
            print ("HeartRate Sample Type is no longer available for HealthKit")
            return
        }
        
        ProfileDataStore.getAVGHeartRate(for: heartRateSampleType) { (sample, error) in
            //2. Convert the weight sample to kilos, save to the profile model,
            //   and update the user interface.
            let heartRateInCount = sample
            self.userHealthProfile.heartRate = heartRateInCount
            print(heartRateInCount!)
            
            if let heartRate = self.userHealthProfile.heartRate {
                DispatchQueue.main.async { // Correct
                    self.heartRateLabel.text = "Your heart rate: " + heartRate.description
                    self.label.text  = "Done!"
                }
            }
            
        }
    }
    
    @IBAction func authSwitchToggled(_ sender: UISwitch) {
        mqttSetting()
        mqtt?.connect()
        changeSwitchText()
    }
    
    func changeSwitchText() {
        timer?.invalidate()
        
        if authSwitch.isOn {
            label.text = "Wait, we are listening to your heart!"
            authorizeHealthKit()
            timer = Timer.scheduledTimer(timeInterval: 0.97, target: self, selector: #selector(self.loadAndDisplayHeartRate), userInfo: nil, repeats: true)
        } else {
            label.text = "tell 'em all"
            self.heartRateLabel.text = "Your heart rate: -"
        }
    }
}

extension FirstViewController: CocoaMQTTDelegate {
    // Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        TRACE("trust: \(trust)")

        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        TRACE("ack: \(ack)")
        
        if ack == .accept {
            mqtt.subscribe("chat/room/animals/client", qos: CocoaMQTTQOS.qos1)
            print("hellooooo")

           
                DispatchQueue.main.async { // Correct
                    self.message = self.userHealthProfile.heartRate?.description
                    self.timer = Timer.scheduledTimer(timeInterval: 19.7, target: self, selector: #selector(self.publish), userInfo: nil, repeats: true)
                    
                }
            
        }
        
    }
    
    @objc func publish(){

        
        let json: JSON =  ["deviceID":deviceId,
                           "deviceName":deviceName,
                           "healthData": ["heartRate": self.heartRateLabel.text],
                           "location": ["latitude":lat,"longitude":lon]
                            ]

        mqtt?.publish("way/pi3/WayCEPEngine/oley" , withString:json.description , qos: .qos1)
        print(deviceId)
        print(deviceName)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        TRACE("new state: \(state)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message: \(message.string!.description), id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        TRACE("id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        TRACE("message: \(message.string!.description), id: \(id)")
        
        let name = NSNotification.Name(rawValue: "MQTTMessageNotification" )
        NotificationCenter.default.post(name: name, object: self, userInfo: ["message": message.string!, "topic": message.topic])
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        TRACE("topic: \(topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        TRACE("topic: \(topic)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        TRACE()
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        TRACE()
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        //TRACE("\(err.description)")
    }
}

extension FirstViewController {
    func TRACE(_ message: String = "", fun: String = #function) {
        let names = fun.components(separatedBy: ":")
        var prettyName: String
        if names.count == 1 {
            prettyName = names[0]
        } else {
            prettyName = names[1]
        }
        
        if fun == "mqttDidDisconnect(_:withError:)" {
            prettyName = "didDisconect"
        }
        
        print("[TRACE] [\(prettyName)]: \(message)")
    }
}


