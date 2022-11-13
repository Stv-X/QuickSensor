//
//  NetworkSupport.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/11/2.
//

import Foundation
import Network

let serverQueue = DispatchQueue(label: "TCP Server Queue")

var listener = try! NWListener(using: .tcp)
