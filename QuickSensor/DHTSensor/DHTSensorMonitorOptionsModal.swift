//
//  DHTSensorMonitorOptionsModal.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/11/4.
//

import SwiftUI
import Network

struct DHTSensorMonitorOptionsModal: View {
    @Binding var isPresented: Bool
    @Binding var options: DHTSensorMonitorOptions
    @Binding var isNetworkEndPointPortNumberInvalid: Bool
    
    @State private var onEditingOptions = DHTSensorMonitorOptions()
    
    var body: some View {
        VStack {
            Form {
                
                // Hostname Field
                HStack {
                    Text("Connect to address")
                    Spacer()
                    TextField("", text: $onEditingOptions.hostname)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                .frame(maxHeight: 20)
                
                // Port Field
                HStack {
                    Text("Port")
                    Spacer()
                    TextField("", text: $onEditingOptions.port)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                .frame(maxHeight: 20)
                
                // Serial Port Picker
                Picker("COM Port", selection: $onEditingOptions.serialPort) {
                    ForEach(0..<8) { i in
                        Text("COM \(i)")
                            .tag(i)
                    }
                }
                
                // Baud Rate Stepper
                Stepper {
                    HStack {
                        Text("Baud Rate")
                        Spacer()
                        Text("\(availableBaudRates[onEditingOptions.baudRateIndex])")
                    }
                } onIncrement: {
                    baudRateIncrementStep()
                } onDecrement: {
                    baudRateDecrementStep()
                }
            }
            .formStyle(.grouped)
#if os(macOS)
            .frame(width: 320)
#endif
            
#if os(macOS)
            Divider()
            
            // Buttons
            HStack {
                Spacer()
                
                Button("Confirm") {
                    if onEditingOptions.port.isNWPort() {
                        options = onEditingOptions
                        connection = NWConnection(host: NWEndpoint.Host(options.hostname),
                                                  port: NWEndpoint.Port(options.port)!,
                                                  using: .tcp)
                        isPresented.toggle()
                    } else {
                        isNetworkEndPointPortNumberInvalid = true
                    }
                }
                .alert(isPresented: $isNetworkEndPointPortNumberInvalid) {
                    Alert(title: Text("Invalid Port"),
                          message: Text("Please check your port."),
                          dismissButton: .default(Text("OK")))
                }
                
                .keyboardShortcut(.defaultAction)
                
                Button("Cancel") {
                    isPresented.toggle()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
#endif
        }
        .onAppear {
            onEditingOptions = options
        }
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Confirm") {
                    if onEditingOptions.port.isNWPort() {
                        options = onEditingOptions
                        connection = NWConnection(host: NWEndpoint.Host(options.hostname),
                                                  port: NWEndpoint.Port(options.port)!,
                                                  using: .tcp)
                        isPresented.toggle()
                    } else {
                        isNetworkEndPointPortNumberInvalid = true
                    }
                }
                .alert(isPresented: $isNetworkEndPointPortNumberInvalid) {
                    Alert(title: Text("Invalid Port"),
                          message: Text("Please check your port."),
                          dismissButton: .default(Text("OK")))
                }
                .keyboardShortcut(.defaultAction)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented.toggle()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
#endif
    }
    
    private func baudRateIncrementStep() {
        onEditingOptions.baudRateIndex -= 1
        
        if onEditingOptions.baudRateIndex <= 0 {
            onEditingOptions.baudRateIndex = availableBaudRates.count - 1
        }
    }
    
    private func baudRateDecrementStep() {
        onEditingOptions.baudRateIndex += 1
        
        if onEditingOptions.baudRateIndex > availableBaudRates.count - 1 {
            onEditingOptions.baudRateIndex = 0
        }
    }
}
