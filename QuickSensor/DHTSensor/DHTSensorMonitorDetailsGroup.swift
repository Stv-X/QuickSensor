//
//  DHTSensorMonitorDetailsGroup.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/11/5.
//

import SwiftUI

struct DHTSensorMonitorDetailsGroup: View {
    @Binding var receivedRawData: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                GroupBox {
                    Text(receivedRawData.readableBinary())
                        .font(.system(.body, design: .monospaced))
#if os(macOS)
                        .frame(width: 394)
#endif
                        .contextMenu {
                            Button {
                                copyToClipBoard(textToCopy: receivedRawData)
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                    
                } label: {
                    Text("Raw Data")
                }
                
                HStack {
                    GroupBox {
                        Text("\(formattedRawData(from: receivedRawData).humidityHigh.readableBinary()) \(formattedRawData(from: receivedRawData).humidityLow.readableBinary())")
                            .font(.system(.body, design: .monospaced))
#if os(macOS)
                            .frame(width: 164)
#endif
                            .contextMenu {
                                Button {
                                    copyToClipBoard(textToCopy: formattedRawData(from: receivedRawData).humidityHigh + formattedRawData(from: receivedRawData).humidityLow)
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                            }
                        
                    } label: {
                        Text("Humidity Raw Data")
                    }
                    
                    GroupBox {
                        Text("\(formattedRawData(from: receivedRawData).temperatureHigh.readableBinary()) \(formattedRawData(from: receivedRawData).temperatureLow.readableBinary())")
                            .font(.system(.body, design: .monospaced))
#if os(macOS)
                            .frame(width: 164)
#endif
                            .contextMenu {
                                Button {
                                    copyToClipBoard(textToCopy: formattedRawData(from: receivedRawData).temperatureHigh + formattedRawData(from: receivedRawData).temperatureLow)
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                            }
                        
                    } label: {
                        Text("Temperature Raw Data")
                    }
                }
                
                GroupBox {
                    Text(formattedRawData(from: receivedRawData).verifyBit.readableBinary())
                        .font(.system(.body, design: .monospaced))
#if os(macOS)
                        .frame(width: 74)
#endif
                        .contextMenu {
                            Button {
                                copyToClipBoard(textToCopy: formattedRawData(from: receivedRawData).verifyBit)
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                    
                } label: {
                    Text("Verify Bit")
                }
                
                Spacer()
            }
            Spacer()
            
        }
    }
    private func formattedRawData(from rawData: String) -> DHTRawData {
        let splitedRawData = rawData.split(separator: "")
        var formattedRawData: [Int] = []
        for i in splitedRawData {
            formattedRawData.append(Int(i)!)
        }
        var rawData = DHTRawData(humidityHigh: "", humidityLow: "", temperatureHigh: "", temperatureLow: "", verifyBit: "")
        
        rawData.map(from: formattedRawData)
        return rawData
    }
}
