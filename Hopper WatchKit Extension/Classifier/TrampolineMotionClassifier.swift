//
//  TrampolineMotionClassifier.swift
//  Hopper WatchKit Extension
//
//  Created by MacBook Pro M1 on 2021/04/12.
//

import Foundation
import CoreML
import CoreMotion
import Combine
import HealthKit

class TrampolineMotionClassifier: NSObject, ObservableObject, HKWorkoutSessionDelegate {
    
    /// - Tag: MLModel for detection of motion on a trampoline
    private let model: VGG16 = {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            return try VGG16(configuration: config)
        } catch {
            print(error)
            fatalError("Couldn't create VGG16")
        }
    }()
    
    let predictionWindowLength = 64 * 3
    var inputData = [Double]()
    
    // Publish the following:
    // - predicted motion
    // - confidence of predicted motion
    // - x-axis acceleration data
    // - y-axis acceleration data
    // - z-axis acceleration data
    @Published var prediction: String = "None"
    @Published var confidence: Double = 0.0
    
    @Published var x = 0.0
    @Published var y = 0.0
    @Published var z = 0.0
    
    // CMMotionManager
    var motionManager = CMMotionManager()
    
    // Timer
    private var timer = Timer()
    
    /// - Tag: Workout session
    var session: HKWorkoutSession!
    
    /// - Tag: WCSession
    var connector = PhoneConnector()
    
    /// Processing when the sensor data value is acquired
    @objc private func startSensor() {
        if let data = self.motionManager.accelerometerData {
            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            
            self.x = x
            self.y = y
            self.z = z
            
            self.inputData.append(x)
            self.inputData.append(y)
            self.inputData.append(z)
        }
        else {
            self.x = Double.nan
            self.y = Double.nan
            self.z = Double.nan
        }
        
//        let timestamp = getTimestamp()
//        print("\(timestamp) \(self.x),\(self.y),\(self.z)")
        
        if self.inputData.count == self.predictionWindowLength {
            // [Double] to MLMultiArray
            guard let inputDataMLMultiArray = try? MLMultiArray.fromDouble(self.inputData) else {
                fatalError("Couldn't initialize MLMultiArray from Double array")
            }
            
            let startTime = Date()
            
            // Predict motion
            guard let output = try? self.model.prediction(input: inputDataMLMultiArray) else {
                fatalError("Unexpected runtime error")
            }
            
            let finishTime = Date()
            let predictionTime = finishTime.timeIntervalSince(startTime)
            print("Prediction time: \(predictionTime)")
            
            // Save prediction
            self.prediction = output.classLabel
            self.confidence = output.Identity[self.prediction]!
            
            print("Prediction: \(self.prediction) (\(self.confidence))")
            
            // Reset inputData
            self.inputData = [Double]()
            
            // Send prediction to iPhone
            if self.connector.send(key: "Prediction", value: self.prediction) {
                print("Success: send Prediction")
            }
            
            if self.connector.send(key: "Confidence", value: self.confidence) {
                print("Success: send Confidence")
            }
        }
    }
    
    /// Start measuring the sensor data
    func startUpdate(_ frequency: Double) {
        if self.motionManager.isAccelerometerAvailable {
            self.motionManager.startAccelerometerUpdates()
        }
        
        // MARK: - Workout Session
        let config = HKWorkoutConfiguration()
        config.activityType = .fitnessGaming
        config.locationType = .indoor
        
        let healthStore = HKHealthStore()
        
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]
        
        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle error.
        }
        
        session = try! HKWorkoutSession(healthStore: healthStore, configuration: config)
        session.delegate = self
        
        session.startActivity(with: Date())
        
        // MARK: - Timer
        self.timer = Timer.scheduledTimer(timeInterval: 1.0 / frequency,
                                          target: self,
                                          selector: #selector(self.startSensor),
                                          userInfo: nil,
                                          repeats: true)
        
        if self.connector.send(key: "Running", value: true) {
            print("Success: isRunning = true")
        }
    }
    
    /// Stop measuring the sensor data
    func stopUpdate() {
        self.timer.invalidate()
        
        if self.motionManager.isAccelerometerActive {
            self.motionManager.stopAccelerometerUpdates()
        }
        
        if self.connector.send(key: "Running", value: false) {
            print("Success: isRunning = false")
        }
        
        self.inputData = [Double]()
        
        session.end()
    }
    
    // MARK: -
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        if toState == .ended {
            print("The workout has now ended.")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
}
