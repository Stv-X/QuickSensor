//
//  THSensorSupport.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/22.
//

import SwiftUI
import UniformTypeIdentifiers
import Charts

enum TemperatureLevel: String, CaseIterable, Identifiable {
    case low
    case medium
    case high
    
    var id: Self { self }
}

struct TemperatureRecord: Identifiable {
    var value: Double
    var timestamp: Date
    var id = UUID()
}

struct HumidityRecord: Identifiable {
    var value: Double
    var timestamp: Date
    var id = UUID()
}

struct TemperatureState: Equatable {
    var value: Double
}

struct HumidityState: Equatable {
    var value: Double
}

struct OrganizedData {
    var temperature: TemperatureState
    var humidity: HumidityState
    var isVerified: Bool
}

struct THRawData {
    var humidityHigh: String
    var humidityLow: String
    var temperatureHigh: String
    var temperatureLow: String
    var verifyBit: String
}

var availableBaudRates: [Int] = [115200, 57600, 38400, 19200, 14400, 9600]

struct THSensorMonitorOptions {
    var serialPort: Int = 0
    var baudRate: Int = availableBaudRates.last!
}

func randomTHSensorRawData() -> String {
    var data = ""
    var temperature: Int
    var humidity: Int
    
    var humidityRawData: String
    var temperatureRawData: String
    
    var humidityRawHigh: String
    var humidityRawLow: String
    var temperatureRawHigh: String
    var temperatureRawLow: String
    
    repeat {
    humidity = Int.random(in: 0...1000)
    temperature = Int.random(in: -200...800)
    
    humidityRawData = rawData(of: humidity)
    temperatureRawData = rawData(of: temperature)
    
    humidityRawHigh = highBit(of: humidityRawData)
    humidityRawLow = lowBit(of: humidityRawData)
    temperatureRawHigh = highBit(of: temperatureRawData)
    temperatureRawLow = lowBit(of: temperatureRawData)
        
    } while humidityRawHigh.toDec() + humidityRawLow.toDec() + temperatureRawHigh.toDec() + temperatureRawLow.toDec() > 255
    
    let verifyBitValue = humidityRawHigh.toDec() + humidityRawLow.toDec() + temperatureRawHigh.toDec() + temperatureRawLow.toDec()
    
    var formattedVerifyBitValue = verifyBitValue.binary
    while formattedVerifyBitValue.count < 8 {
        formattedVerifyBitValue = "0" + formattedVerifyBitValue
    }
    
    data = humidityRawData + temperatureRawData + formattedVerifyBitValue
    
    return data
}

func rawData(of data: Int) -> String {
    var rawData = ""
    if data < 0 {
        rawData = (-data).binary
    } else {
        rawData = data.binary
    }
    if data < 0 {
        while rawData.count < 15 {
            rawData = "0" + rawData
        }
        rawData = "1" + rawData
        
    } else {
        
        while rawData.count < 16 {
            rawData = "0" + rawData
        }
    }
    return rawData
}

func highBit(of rawData: String) -> String {
    var highBit = ""
    
    for i in 0..<8 {
        highBit += rawData.split(separator: "")[i]
    }
    
    return highBit
}

func lowBit(of rawData: String) -> String {
    var lowBit = ""
    
    for i in 8..<16 {
        lowBit += rawData.split(separator: "")[i]
    }
    
    return lowBit
}

func copyToClipBoard(textToCopy: String) {
#if os(macOS)
    let pasteBoard = NSPasteboard.general
    pasteBoard.clearContents()
    pasteBoard.setString(textToCopy, forType: .string)
#else
    UIPasteboard.general.setValue(textToCopy, forPasteboardType: UTType.plainText.identifier)
#endif
}

extension Int: Identifiable {
    public typealias ID = Int
    public var id: ID {
        return self
    }
}

extension THRawData {
    mutating func map(from formattedRawData: [Int]) {
        for i in 0..<8 {
            self.humidityHigh += "\(formattedRawData[i])"
            self.humidityLow += "\(formattedRawData[i + 8])"
            self.temperatureHigh += "\(formattedRawData[i + 16])"
            self.temperatureLow += "\(formattedRawData[i + 24])"
            self.verifyBit += "\(formattedRawData[i + 32])"
        }
    }
}


extension String {
    func isBinary() -> Bool {
        var isBinary = true
        
        if !self.contains("1") && !self.contains("0") {
            isBinary = false
        }
        
        return isBinary
    }
    
    func readableBinary() -> String {
        if self.isBinary() {
            let splitedBin = self.split(separator: "")
            var readableBin = ""
            
            for i in 0..<splitedBin.count {
                readableBin += "\(splitedBin[i])"
                if (i + 1) % 4 == 0 {
                    readableBin += " "
                }
            }
            return readableBin
        } else {
            return self
        }
    }
    
    mutating func toDec() -> Int {
        if self.isBinary() {
            var sum = 0
            for character in self {
                sum = sum * 2 + Int("\(character)")!
            }
            
            return sum
        } else {
            return 0
        }
    }
    
    mutating func toTDec() -> Int {
        if self.isBinary() {
            var sum = 0
            var isNegative = false
            
            if self.first == "1" {
                isNegative = true
            }
            if isNegative {
                var oppositeNum = ""
                let splitedBin = self.split(separator: "")
                
                for character in 1..<splitedBin.count {
                    oppositeNum += "\(splitedBin[character])"
                }
                
                for character in oppositeNum {
                    sum = sum * 2 + Int("\(character)")!
                }
                
                return -sum
                
            } else {
                
                for character in self {
                    sum = sum * 2 + Int("\(character)")!
                }
                
                return sum
            }
        } else {
            return 0
        }
    }
    
}

extension Int {
    var binary: String {
        return String(self, radix: 2)
    }
}
