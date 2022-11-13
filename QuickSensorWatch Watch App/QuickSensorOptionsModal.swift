//
//  QuickSensorOptionsModal.swift
//  QuickSensorWatch Watch App
//
//  Created by 徐嗣苗 on 2022/11/12.
//

import SwiftUI
import Network

struct QuickSensorOptionsModal: View {
    @Binding var isPresented: Bool
    @Binding var options: SensorMonitorOptions
    @State private var onEditingOptions = SensorMonitorOptions()
    @State private var isNetworkEndPointPortNumberInvalid: Bool = false
    
    var body: some View {
        
        VStack {
            Form {
                Text("IP")
                Text(wifiIP!)
                // Port Field
                HStack {
                    Text("Port")
                    Spacer()
                    TextField("", text: $onEditingOptions.port)
                        .multilineTextAlignment(.trailing)
                }
                
                
            }
            
            
        }
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
            }
        }
        .onAppear {
            onEditingOptions = options
        }
        
    }
}

struct QuickSensorOptionsModal_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuickSensorOptionsModal(isPresented: .constant(true),
                                    options: .constant(SensorMonitorOptions()))
        }
    }
}
