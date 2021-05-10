//
//  TrampolineMotion.swift
//  Hopper
//
//  Created by MacBook Pro M1 on 2021/05/10.
//

import Foundation

enum TrampolineMotionLabel: String, CaseIterable {
    case stand = "stand"
    case walk = "walk"
    case march = "march"
    case twoJump = "two-jump"
    case oneJumpLeft = "one-jump-left"
    case oneJumpRight = "one-jump-right"
}

struct TrampolineMotionCount {
    var stand = 0
    var walk = 0
    var march = 0
    var twoJump = 0
    var oneJumpLeft = 0
    var oneJumpRight = 0
    
    mutating func countUp(motion: TrampolineMotionLabel)  {

        switch motion {
        case .stand:
            stand += 1
        case .walk:
            walk += 1
        case .march:
            march += 1
        case .twoJump:
            twoJump += 1
        case .oneJumpLeft:
            oneJumpLeft += 1
        case .oneJumpRight:
            oneJumpRight += 1
        }
    }
}
