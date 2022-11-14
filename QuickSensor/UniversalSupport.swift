//
//  UniversalSupport.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/30.
//

import SwiftUI
import UniformTypeIdentifiers
import Network

enum SensorCategory {
    case illuminance, dht
}

struct SensorMonitorOptions {
    var port: String = "8080"
}

// 将字符串拷贝到系统剪贴板
func copyToClipBoard(textToCopy: String) {
#if os(macOS)
    let pasteBoard = NSPasteboard.general
    pasteBoard.clearContents()
    pasteBoard.setString(textToCopy, forType: .string)
#elseif os(iOS)
    UIPasteboard.general.setValue(textToCopy,
                                  forPasteboardType: UTType.plainText.identifier)
#endif
}

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


var wifiIP: String? {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
    
    guard getifaddrs(&ifaddr) == 0 else {
        return nil
    }
    guard let firstAddr = ifaddr else {
        return nil
    }
    
    for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let interface = ifptr.pointee
        // Check for IPV4 or IPV6 interface
        let addrFamily = interface.ifa_addr.pointee.sa_family
        if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
            // Check interface name
            let name = String(cString: interface.ifa_name)
            if name == "en0" {
                // Convert interface address to a human readable string
                var addr = interface.ifa_addr.pointee
                var hostName = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(&addr,socklen_t(interface.ifa_addr.pointee.sa_len), &hostName, socklen_t(hostName.count), nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostName)
            }
        }
    }
    
    freeifaddrs(ifaddr)
    return address
}

extension Data {
    func hexadecimal() -> String {
        return map { String(format: "%02x", $0) }
            .joined(separator: " ")
    }
}
