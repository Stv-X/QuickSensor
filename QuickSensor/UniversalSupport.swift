//
//  UniversalSupport.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/30.
//

import SwiftUI
import UniformTypeIdentifiers
import Network

// 将字符串拷贝到系统剪贴板
func copyToClipBoard(textToCopy: String) {
#if os(macOS)
    let pasteBoard = NSPasteboard.general
    pasteBoard.clearContents()
    pasteBoard.setString(textToCopy, forType: .string)
#else
    UIPasteboard.general.setValue(textToCopy,
                                  forPasteboardType: UTType.plainText.identifier)
#endif
}

// 可选的波特率
let availableBaudRates: [Int] = [460800, 345600, 230400, 115200, 57600, 38400, 19200, 9600, 4800, 2400, 1800, 1200, 600, 300]

extension Int: Identifiable {
    public typealias ID = Int
    public var id: ID {
        return self
    }
    
    // 将整型数字转换为二进制字符串
    // 例: 89.binary() -> "01011001"
    var binary: String {
        return String(self, radix: 2)
    }
}

extension String {
    
    // 判断字符串是否为二进制数字
    // 例: "01011001".isBinary() -> true
    func isBinary() -> Bool {
        var isBinary = true
        let splitedString = self.split(separator: "")
        
        if self == "" {
            return false
        }
        
        for character in splitedString {
            if character != "0" && character != "1" {
                isBinary = false
                break
            }
        }
        
        return isBinary
    }
    
    // 判断字符串是否能用于端口号
    // 例: "8080".isNWPort() -> true
    func isNWPort() -> Bool {
        var isNWPort = true
        
        if NWEndpoint.Port(self) != nil {
            
        } else {
            isNWPort = false
        }
        
        return isNWPort
    }
    
    // 将二进制字符串转换为每 4 位空一格的易读形式
    // 例: "01011001".readableBinary() -> "0101 1001"
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
    
    // 将二进制字符串转换为十进制数字
    // 例: "01011001".toDec() -> 89
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
    
}
