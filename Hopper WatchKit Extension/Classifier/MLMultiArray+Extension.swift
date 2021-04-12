//
//  MLMultiArray+Extension.swift
//  Hopper WatchKit Extension
//
//  Created by MacBook Pro M1 on 2021/04/12.
//

import CoreML

extension MLMultiArray {
    static func fromDouble(_ input: [Double]) throws -> MLMultiArray {
        let mlArray = try! MLMultiArray(shape: [1, input.count as NSNumber], dataType: .double)
        let ptr = mlArray.dataPointer.bindMemory(to: Double.self, capacity: input.count)
        let ptrBuf = UnsafeMutableBufferPointer.init(start: ptr, count: input.count)
        _ = ptrBuf.initialize(from: input)
        return mlArray
    }
}
