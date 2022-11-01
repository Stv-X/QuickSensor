//
//  TCPSupport.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/11/1.
//

import Foundation

class TCPSupport {
    
    var stateText = ""
    
    //TCP服务端
    var server:SynchronousTCPServer!
    
    //TCP客户端
    lazy var client:TCPClient? = {
        //初始化客户端
        let address = InternetAddress(hostname: "127.0.0.1", port: 8080)
        do {
            return try TCPClient(address: address)
        } catch {
            print("Error \(error)")
            return nil
        }
    }()
    
    //启动服务器
    func startServer() {
        //在后台线程中启动服务器
        DispatchQueue.global(qos: .background).async {
            do {
                //初始化服务器
                self.server = try SynchronousTCPServer(port: 8080)
                
                //在界面上显示启动信息
                DispatchQueue.main.async {
                    let hostname = self.server.address.hostname
                    let address = self.server.address.addressFamily
                    let port = self.server.address.port
                    self.stateText = "服务器启动，监听："
                    + "\"\(hostname)\" (\(address)) \(port)\n"
                }
                
                //接收并处理客户端连接
                try self.server.startWithHandler { (client) in
                    self.handleClient(client: client)
                }
            } catch {
                print("Error \(error)")
            }
        }
    }
    
    //处理连接的客户端
    func handleClient(client:TCPClient){
        do {
            while true{
                //获取客户端发送过来的消息：[UInt8]类型
                let data = try client.receiveAll()
                
                //将接收到的消息转成String类型
                let str = try data.toString()
                //将这个String消息显示到界面上
                DispatchQueue.main.async {
                    self.stateText = self.textView.text + "服务端接收到消息: \(str)\n"
                }
                
                //将接收到的消息又发回客户端
                try client.send(bytes: data)
                
                //try client.close() //关闭与客户端链接
            }
        } catch {
            print("Error \(error)")
        }
    }
    
}
