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

func randomIlluminance() -> Bool {
    let seed = Int.random(in: 0...1)
    
    if seed == 0 {
        return false
    } else {
        return true
    }
    
}

func illuminanceParsedFrom(_ rawValue: String) -> Bool {
    if rawValue == "EE CC 02 NO 01 00 00 00 00 00 01 00 00 FF" {
        return true
    } else {
        return false
    }
}

extension String {
    func isIlluminanceRawData() -> Bool {
        if self == "EE CC 02 NO 01 00 00 00 00 00 01 00 00 FF" || self == "EE CC 02 NO 01 00 00 00 00 00 00 00 00 FF" {
            return true
        } else {
            return false
        }
    }
}
