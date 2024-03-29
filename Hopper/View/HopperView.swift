//
//  HooperView.swift
//  Hopper
//
//  Created by MacBook Pro M1 on 2021/04/12.
//

import SwiftUI

struct HopperView: View {
    @ObservedObject var connector = WatchConnector.shared
    
    var body: some View {
        VStack {
            Spacer()
            Text("Trampoline Motion Classifier")
                .foregroundColor(.secondary)
                .font(.title2)
            VStack {
                Text(self.connector.runinng ? self.connector.prediction : "Prepare")
                    .foregroundColor(.accentColor)
                    .font(.largeTitle)
                Text(self.connector.runinng ? "\(self.connector.confidence)" : "")
                    .fontWeight(.semibold)
                    .font(.title3)
                    .padding(.vertical, 10)
            }.padding(.vertical, 50)
            Spacer()
        }
        .sheet(isPresented: $connector.isPresented, content: {
            NavigationView {
                SummaryView()
                    .navigationTitle("Hopper")
                    .navigationBarItems(trailing:
                                            Button(action: {
                                                self.connector.isPresented = false
                                            }, label: {
                                                Text("Done")
                                            }))
            }
        })
    }
}

struct HooperView_Previews: PreviewProvider {
    static var previews: some View {
        HopperView()
            .preferredColorScheme(.dark)
    }
}
