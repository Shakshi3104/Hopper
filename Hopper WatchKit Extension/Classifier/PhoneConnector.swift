//
//  PhoneConnector.swift
//  Hopper WatchKit Extension
//
//  Created by MacBook Pro M1 on 2021/04/14.
//

import Foundation
import WatchConnectivity

class PhoneConnector: NSObject, WCSessionDelegate {
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith state=\(activationState.rawValue)")
    }
    
    func send(key: String, value: Any) -> Bool {
        var isSuccess = false
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage([key: value], replyHandler: nil) { error in
                print(error)
                isSuccess = false
            }
            
            isSuccess = true
        }
        
        return isSuccess
    }
}
