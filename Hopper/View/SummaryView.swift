//
//  SummaryView.swift
//  Hopper
//
//  Created by MacBook Pro M1 on 2021/05/10.
//

import SwiftUI

struct SummaryView: View {
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
                FitnessTotalTimeListRow(timeInterval: connector.totalTime)
                FitnessListRow(key: "Active Kilocalories", value: "\(Int(connector.activeCalories))", unit: "KCAL", foregroundColor: .pink)
                FitnessListRow(key: "Avg. Heart Rate", value: "\(Int(connector.avgHeartRate))", unit: "BPM", foregroundColor: .red)
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

struct FitnessTotalTimeListRow: View {
    var timeInterval: TimeInterval
    
    var body: some View {
        HStack {
            Text("Total Time")
                .font(Font.system(.body, design: .rounded))
            Spacer()
            Text(self.convertTimeIntervalToString())
                .font(Font.system(.body, design: .rounded).monospacedDigit())
                .foregroundColor(.yellow)
        }
    }
    
    private func convertTimeIntervalToString() -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: timeInterval) ?? "NaN"
    }
}

struct FitnessListRow: View {
    var key: String
    var value: String
    var unit: String
    var foregroundColor: Color = .secondary
    
    var body: some View {
        HStack {
            Text(key)
                .font(Font.system(.body, design: .rounded))
            Spacer()
            HStack(alignment: .bottom) {
                Text(value)
                    .font(Font.system(.body, design: .rounded).monospacedDigit())
                    .foregroundColor(foregroundColor)
                Text(unit)
                    .font(Font.system(.footnote, design: .rounded))
                    .foregroundColor(foregroundColor)
            }
        }
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView()
            .preferredColorScheme(.dark)
    }
}
