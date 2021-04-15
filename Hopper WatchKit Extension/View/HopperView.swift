//
//  HopperView.swift
//  Hopper WatchKit Extension
//
//  Created by MacBook Pro M1 on 2021/04/12.
//

import SwiftUI

struct HopperView: View {
    @State private var isRunning = false
    @ObservedObject var classifier = TrampolineMotionClassifier()
    
    var body: some View {
        VStack {
            Text(isRunning ? classifier.prediction : "Prepare")
                .foregroundColor(.accentColor)
                .font(.title3)
            Text(isRunning ? "\(classifier.confidence)" : "")
                .padding()
            Button(action: {
                self.isRunning.toggle()
                
                if self.isRunning {
                    self.classifier.startUpdate(100.0)
                }
                else {
                    self.classifier.stopUpdate()
                }
                
            }, label: {
                if self.isRunning {
                    Text("Stop")
                }
                else {
                    Text("Start")
                }
            })
        }
    }
}

struct HopperView_Previews: PreviewProvider {
    static var previews: some View {
        HopperView()
    }
}
