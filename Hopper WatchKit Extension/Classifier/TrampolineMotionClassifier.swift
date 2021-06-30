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
import WatchKit

class TrampolineMotionClassifier: NSObject, ObservableObject {
    
    /// - Tag: MLModel for detection of motion on a trampoline
    private let model: VGG16_GAP = {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            return try VGG16_GAP(configuration: config)
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
    var builder: HKLiveWorkoutBuilder!
    
    /// - Tag: Workout statistics
    // - heartrate
    // - activae calories
    var heartrates: [Double] = []
    var activeCalories: Double = 0
    
    // start date
    var startDate: Date!
    
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
        builder = session.associatedWorkoutBuilder()
        session.delegate = self
        builder.delegate = self
        
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: config)
        
        session.startActivity(with: Date())
        builder.beginCollection(withStart: Date()) { (success, error) in
            // The workout has started.
        }
        
        // MARK: - Timer
        self.timer = Timer.scheduledTimer(timeInterval: 1.0 / frequency,
                                          target: self,
                                          selector: #selector(self.startSensor),
                                          userInfo: nil,
                                          repeats: true)
        
        self.startDate = Date()
        
        // Send running state to iPhone
        if self.connector.send(key: "Running", value: true) {
            print("Success: isRunning = true")
        }
        
        // Start feedback
        WKInterfaceDevice.current().play(.start)
    }
    
    /// Stop measuring the sensor data
    func stopUpdate() {
        self.timer.invalidate()
        
        if self.motionManager.isAccelerometerActive {
            self.motionManager.stopAccelerometerUpdates()
        }
        
        // Send running state to iPhone
        if self.connector.send(key: "Running", value: false) {
            print("Success: isRunning = false")
        }
        
        // Send calorie
        if self.connector.send(key: "Energy", value: self.activeCalories) {
            print("Success: activeCalories = \(self.activeCalories)")
        }
        
        // Send avg. heart rate
        let avgHeartRate =  heartrates.count != 0 ? heartrates.reduce(0, +) / Double(heartrates.count) : 0
        if self.connector.send(key: "Heartrate", value: avgHeartRate) {
            print("Success: avgHeartRate = \(avgHeartRate)")
        }
        
        // Send workout time
        let workoutTime = Date().timeIntervalSince(self.startDate)
        if self.connector.send(key: "TotalTime", value: workoutTime) {
            print("Success: workoutTime = \(workoutTime)")
        }
        
        self.inputData = [Double]()
        self.resetWorkout()
        
        // End workout
        session.end()
        
        // Stop feedback
        WKInterfaceDevice.current().play(.stop)
    }
    
    // MARK: -
    func resetWorkout() {
        self.activeCalories = 0
        self.heartrates = []
    }
    
    // MARK: - Update statistics
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        
        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
            let roundedValue = Double( round(1 * value! ) / 1)
            self.heartrates.append(roundedValue)
        case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
            let energyUnit = HKUnit.kilocalorie()
            let value = statistics.sumQuantity()?.doubleValue(for: energyUnit)
            self.activeCalories = Double( round(1 * value!) / 1)
        default:
            return
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension TrampolineMotionClassifier: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        if toState == .ended {
            print("The workout has now ended.")
            builder.endCollection(withEnd: Date()) { success, error in
                self.resetWorkout()
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension TrampolineMotionClassifier: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return
            }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            updateForStatistics(statistics)
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
    
    
}
