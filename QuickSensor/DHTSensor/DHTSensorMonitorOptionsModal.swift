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
                // Port Field
                HStack {
                    Text("Port")
                    Spacer()
                    TextField("", text: $onEditingOptions.port)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                .frame(maxHeight: 20)
                
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
                        listener = try! NWListener(using: .tcp, on: NWEndpoint.Port(options.port)!)
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
                        listener = try! NWListener(using: .tcp, on: NWEndpoint.Port(options.port)!)
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
}
