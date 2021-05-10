//
//  SummaryView.swift
//  Hopper
//
//  Created by MacBook Pro M1 on 2021/05/10.
//

import SwiftUI

struct SummaryView: View {
    @Binding var isPresent: Bool
    @ObservedObject var connector = WatchConnector.shared
    
    var body: some View {
        List {
            Section(header: Text("Summary")) {
                ListRow(key: "stand", value: "\(connector.motionCount.stand)")
                ListRow(key: "walk", value: "\(connector.motionCount.walk)")
                ListRow(key: "march", value: "\(connector.motionCount.march)")
                ListRow(key: "two-jump", value: "\(connector.motionCount.twoJump)")
                ListRow(key: "one-jump-left", value: "\(connector.motionCount.oneJumpLeft)")
                ListRow(key: "one-jump-right", value: "\(connector.motionCount.oneJumpRight)")
            }
            
            Section(header: Text("Activity")) {
                ListRow(key: "Total Time", value: "0:00:00")
                ListRow(key: "Active Kilocalories", value: "0 KCAL")
                ListRow(key: "Total Kilocalories", value: "0 KCAL")
                ListRow(key: "Avg. Heart Rate", value: "0 BPM")
            }
        }.listStyle(InsetGroupedListStyle())
    }
}

struct ListRow: View {
    var key: String
    var value: String
    
    var body: some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .font(Font.system(.body).monospacedDigit())
                .foregroundColor(.secondary)
        }
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView(isPresent: Binding<Bool>.constant(true))
    }
}
