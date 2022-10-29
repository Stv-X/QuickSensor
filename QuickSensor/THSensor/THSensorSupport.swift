//
//  THSensorSupport.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/22.
//

import SwiftUI
import UniformTypeIdentifiers
import Charts

//温度等级，用于绘制监视器视图中的动态温度计符号
enum TemperatureLevel: String, CaseIterable, Identifiable {
    case low
    case medium
    case high
    
    var id: Self { self }
}

//温度记录，为温度柱状图表提供数据
struct TemperatureRecord: Identifiable {
    var value: Double
    var timestamp: Date
    var id = UUID()
}

//湿度记录，为湿度柱状图表提供数据
struct HumidityRecord: Identifiable {
    var value: Double
    var timestamp: Date
    var id = UUID()
}

//温度状态，包含一个以标准单位真实值表示温度数值的 value 属性
struct TemperatureState: Equatable {
    var value: Double
}

//湿度状态，包含一个以标准单位真实值表示湿度数值的 value 属性
struct HumidityState: Equatable {
    var value: Double
}

//整理好的数据，包含温度状态、湿度状态、校验结果
struct OrganizedData {
    var temperature: TemperatureState
    var humidity: HumidityState
    var isVerified: Bool
}

//经过 DHT22 协议规定分类好的二进制原始数据，包括湿度高8位、湿度低8位、温度高8位、温度低8位、校验位
struct THRawData {
    var humidityHigh: String
    var humidityLow: String
    var temperatureHigh: String
    var temperatureLow: String
    var verifyBit: String
}

//可选的波特率
let availableBaudRates: [Int] = [460800, 345600, 230400, 115200, 57600, 38400, 19200, 9600, 4800, 2400, 1800, 1200, 600, 300]

//温湿度传感器监视器视图中可调节的选项
struct THSensorMonitorOptions {
    var serialPort: Int = 0
    var baudRateIndex: Int = availableBaudRates.count - 1
}


//随机生成满足校验要求的温湿度二进制数据字符串
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

//将十进制温湿度转换为满足 DHT22 协议的 16 位二进制原始数据字符串
//输入: 温湿度的十进制原始数据（比标准单位数据大 10 倍）
//例：rawData(of: 386) -> "0000000100001101"
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

//从 16 位二进制原始数据字符串中获取高 8 位
//例: highBit(of: "0000000100001101") -> "00000001"
func highBit(of rawData: String) -> String {
    var highBit = ""
    
    for i in 0..<8 {
        highBit += rawData.split(separator: "")[i]
    }
    
    return highBit
}

//从 16 位二进制原始数据字符串中获取低 8 位
//例: highBit(of: "0000000100001101") -> "00001101"
func lowBit(of rawData: String) -> String {
    var lowBit = ""
    
    for i in 8..<16 {
        lowBit += rawData.split(separator: "")[i]
    }
    
    return lowBit
}

//将字符串拷贝到系统剪贴板
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
    
    //将格式化后的原始数据对应地记录到 THRawData 的各项属性（湿度高8位、湿度低8位、温度高8位、温度低8位、校验位）中
    //例：
    // let formattedRaw = [0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0]
    // rawData.map(from: formattedRaw) -> THRawData(humidityHigh: "00000010", humidityLow: "10010010", temperatureHigh: "00000001", temperatureLow: "00001101", verifyBit: "10100010")
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
    
    //判断字符串是否为二进制数字
    //例: "01011001".isBinary() -> true
    func isBinary() -> Bool {
        var isBinary = true
        
        if !self.contains("1") && !self.contains("0") {
            isBinary = false
        }
        
        return isBinary
    }
    
    //将二进制字符串转换为每 4 位空一格的易读形式
    //例: "01011001".readableBinary() -> "0101 1001"
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
    
    //将二进制字符串转换为十进制数字
    //例: "01011001".toDec() -> 89
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
    
    //将二进制字符串转换为满足 DHT22 传感器协议的十进制数字
    //                    [当温度低于 0 °C 时温度数据的最高位置 1]
    //例: "01011001".toTDec() -> 89
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

extension Int {
    
    //将整型数字转换为二进制字符串
    //例: 89.binary() -> "01011001"
    var binary: String {
        return String(self, radix: 2)
    }
    
}
