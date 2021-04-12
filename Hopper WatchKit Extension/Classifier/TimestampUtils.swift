//
//  TimestampUtils.swift
//  Hopper WatchKit Extension
//
//  Created by MacBook Pro M1 on 2021/04/12.
//

import Foundation

func getTimestamp() -> String {
    let format = DateFormatter()
    format.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
    return format.string(from: Date())
}
