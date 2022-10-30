//
//  IlluminanceSensorSupport.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/27.
//

import Foundation

struct IlluminanceSensorState: Equatable {
    var isIlluminated: Bool
}

struct IlluminationRecord: Identifiable {
    var isIlluminated: Bool
    var timestamp: Date
    var id = UUID()
}

enum IlluminationState: String {
    case isIlluminated
    case isNotIlluminated
}

struct IlluminationIntervalRecord: Identifiable {
    var state: IlluminationState
    var start: Date
    var end: Date
    var id = UUID()
}
