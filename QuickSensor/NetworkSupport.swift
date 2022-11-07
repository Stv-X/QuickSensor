//
//  NetworkSupport.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/11/2.
//

import Foundation
import Network

let socketQueue = DispatchQueue(label: "TCP Client Queue")

var connection = NWConnection(host: "10.10.100.100",
                              port: 8899,
                              using: .tcp)

var receivedRawData: [String] = []

func connectToServer(host: String, port: String) {
    // 设置连接参数
    var params: NWParameters!
    
    // 使用 TCP 协议
    params = NWParameters.tcp
    // 仅使用 Wi-Fi
    params.prohibitedInterfaceTypes = [.wifi]
    // 禁止代理
    params.preferNoProxies = true
    
    connection = NWConnection(host: NWEndpoint.Host(host),
                              port: NWEndpoint.Port(port)!,
                              using: params)
    
    // 开始连接
    connection.start(queue: socketQueue)
    
    // 监听连接状态
    connection.stateUpdateHandler = {
        (newState) in
        switch newState {
        case .ready:
            print("state ready")
        case .cancelled:
            print("state cancel")
        case .waiting(let error):
            print("state waiting \(error)")
            // 主机拒绝连接，自动断开
            if error == NWError.posix(.ECONNREFUSED) {
                connection.cancel()
            }
        case .failed(let error):
            print("state failed \(error)")
        case .preparing:
            print("state preparing")
        case .setup:
            print("state setup")
        default:
            break
        }
    }
}


func receiveMessage() {
    let maxLengthOfTCPPacket = 65536
    
    connection.receive(minimumIncompleteLength: 1,
                       maximumLength: maxLengthOfTCPPacket,
                       completion: { (content, context, isComplete, receError) in
        if let receError = receError {
            print(receError)
            return
            
        } else {
            let data = String(data: content ?? "".data(using: .utf8)!, encoding: .utf8)
            
            
            if data!.isBinary() {
                receivedRawData.append(data!)
                print("receivedRawData appended \(data!)")
            }
        }
        
        if isComplete {
            // 关闭资源
            connection.cancel()
            return
            
        }
        receiveMessage()
    })
}

func disconnectToServer() {
    connection.cancel()
    
    print(receivedRawData)
    receivedRawData.removeAll()
}

func sendMessage(_ content: String) {
    
    connection.send(content: content.data(using: .utf8),
                    completion: .contentProcessed({ (sendError) in
        if let sendError = sendError {
            print(sendError)
        } else {
            
        }
    }))
}
