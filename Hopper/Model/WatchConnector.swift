//
//  WatchConnector.swift
//  Hopper
//
//  Created by MacBook Pro M1 on 2021/04/14.
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnector: NSObject, WCSessionDelegate, ObservableObject {
    /// - Tag: Stand alone object
    static var shared = WatchConnector()
    
    /// - Tag: Running state
    @Published var runinng: Bool = false
    
    /// - Tag: Trampoline motion prediction
    @Published var prediction: String = "None"
    @Published var confidence: Double = 0.0
    
    @Published var motionCount: TrampolineMotionCount = TrampolineMotionCount()
    
    /// - Tag: Summary view state
    @Published var isPresented: Bool = false
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith state = \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let isRunning = message["Running"] as? Bool {
                print(isRunning)
                self.runinng = isRunning
                
                if isRunning {
                    // Reset motion count
                    self.motionCount = TrampolineMotionCount()
                }
                else {
                    self.isPresented = true
                }
            }
            
            if let prediction = message["Prediction"] as? String {
                print(prediction)
                self.prediction = prediction
                
                let predictionLabel = TrampolineMotionLabel(rawValue: prediction)
                self.motionCount.countUp(motion: predictionLabel!)
            }
            
            if let confidence = message["Confidence"] as? Double {
                print(confidence)
                self.confidence = confidence
            }
        }
    }
}
