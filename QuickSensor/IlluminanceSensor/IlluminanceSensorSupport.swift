//
//  IlluminanceSensorSupport.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/27.
//

import Foundation
import Charts

//  Data Model
struct IlluminanceSensorState: Equatable {
    init() {
        self.isIlluminated = false
    }
    
    init(isIlluminated: Bool) {
        self.isIlluminated = isIlluminated
    }
    
    var isIlluminated: Bool
}

struct IlluminanceRecord: Identifiable {
    var state: IlluminanceSensorState
    var timestamp: Date
    var id = UUID()
}

struct IlluminanceIntervalRecord: Identifiable {
    init(state: IlluminanceSensorState, start: Double, end: Double, startTime: Date, endTime: Date) {
        self.state = state
        self.stateStr = state.isIlluminated ? "Light" : "Dark"
        self.start = start
        self.end = end
        self.startTime = startTime
        self.endTime = endTime
    }
    var state: IlluminanceSensorState
    var stateStr: String
    var start: Double
    var end: Double
    var startTime: Date?
    var endTime: Date?
    var id = UUID()
}

//  Parser
func illuminanceParsedFrom(_ rawValue: String) -> Bool? {
    if rawValue == "ee cc 02 01 01 00 00 00 00 00 01 00 00 ff" {
        return true
    } else if rawValue == "ee cc 02 01 01 00 00 00 00 00 00 00 00 ff" {
        return false
    }
    return nil
}

extension String {
    func isIlluminanceRawData() -> Bool {
        if self == "ee cc 02 01 01 00 00 00 00 00 01 00 00 ff" || self == "ee cc 02 01 01 00 00 00 00 00 00 00 00 ff" {
            return true
        } else {
            return false
        }
    }
}

//  Plot
struct PlottableMeasurement<UnitType: Unit> {
    var measurement: Measurement<UnitType>
}

extension PlottableMeasurement: Plottable where UnitType == UnitDuration {
    var primitivePlottable: Double {
        self.measurement.converted(to: .seconds).value
    }
    
    init?(primitivePlottable: Double) {
        self.init(
            measurement: Measurement(
                value: primitivePlottable,
                unit: .seconds
            )
        )
    }
}
