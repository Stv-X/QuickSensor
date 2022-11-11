//
//  DHTSensorSupport.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/22.
//

import SwiftUI
import UniformTypeIdentifiers
import Charts

var firstElementIsDirty = false

// 温度等级，用于绘制监视器视图中的动态温度计符号
enum TemperatureLevel: String, CaseIterable, Identifiable {
    case low
    case medium
    case high
    
    var id: Self { self }
}

// 温度记录，为温度柱状图表提供数据
struct TemperatureRecord: Identifiable {
    var value: Double
    var timestamp: Date
    var id = UUID()
}

// 湿度记录，为湿度柱状图表提供数据
struct HumidityRecord: Identifiable {
    var value: Double
    var timestamp: Date
    var id = UUID()
}

// 温度状态，包含一个以标准单位真实值表示温度数值的 value 属性
struct TemperatureState: Equatable {
    var value: Double
}

// 湿度状态，包含一个以标准单位真实值表示湿度数值的 value 属性
struct HumidityState: Equatable {
    var value: Double
}

// 整理好的数据，包含温度状态、湿度状态、校验结果
struct OrganizedDHTData {
    var temperature: TemperatureState
    var humidity: HumidityState
    var isVerified: Bool
}

// 经过 DHT22 协议规定分类好的二进制原始数据，包括湿度高8位、湿度低8位、温度高8位、温度低8位、校验位
struct DHTRawData {
    var humidityHigh: String
    var humidityLow: String
    var temperatureHigh: String
    var temperatureLow: String
    var verifyBit: String
}

// 温湿度传感器监视器视图中可调节的选项
struct DHTSensorMonitorOptions {
    var serialPort: Int = 0
    var baudRateIndex: Int = availableBaudRates.count - 1
    var port: String = "8080"
}


// 随机生成满足校验要求的温湿度二进制数据字符串
func randomDHTSensorRawData() -> String {
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
        
        humidityRawData = rawDHTData(of: humidity)
        temperatureRawData = rawDHTData(of: temperature)
        
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

// 将十进制温湿度转换为满足 DHT22 协议的 16 位二进制原始数据字符串
// 输入: 温湿度的十进制原始数据（比标准单位数据大 10 倍）
// 例：rawDHTData(of: 386) -> "0000000100001101"
func rawDHTData(of data: Int) -> String {
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

// 从 16 位二进制原始数据字符串中获取高 8 位
// 例: highBit(of: "0000000100001101") -> "00000001"
func highBit(of rawDHTData: String) -> String {
    var highBit = ""
    
    for i in 0..<8 {
        highBit += rawDHTData.split(separator: "")[i]
    }
    
    return highBit
}

// 从 16 位二进制原始数据字符串中获取低 8 位
// 例: highBit(of: "0000000100001101") -> "00001101"
func lowBit(of rawDHTData: String) -> String {
    var lowBit = ""
    
    for i in 8..<16 {
        lowBit += rawDHTData.split(separator: "")[i]
    }
    
    return lowBit
}

extension DHTRawData {
    
    // 将格式化后的原始数据对应地记录到 DHTRawData 的各项属性（湿度高8位、湿度低8位、温度高8位、温度低8位、校验位）中
    //  例：
    // let formattedRaw = [0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0]
    // rawDHTData.map(from: formattedRaw) -> DHTRawData(humidityHigh: "00000010", humidityLow: "10010010", temperatureHigh: "00000001", temperatureLow: "00001101", verifyBit: "10100010")
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
    
    // 将二进制字符串转换为满足 DHT22 传感器协议的十进制数字
    //                    [当温度低于 0 °C 时温度数据的最高位置 1]
    // 例: "01011001".toTDec() -> 89
    //    "11011001".toTDec() -> -89
    mutating func toDHT22Dec() -> Int {
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
