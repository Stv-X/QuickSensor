//
//  QuickSensorListView.swift
//  QuickSensorWatch Watch App
//
//  Created by 徐嗣苗 on 2022/11/12.
//

import SwiftUI
import Network

struct QuickSensorListView: View {
    @State private var focusedSensor: SensorCategory? = nil
    @State private var isOptionsModalPresented = false
    @State public var options = SensorMonitorOptions()
    
    @State private var currentIlluminanceSensorState = IlluminanceSensorState(isIlluminated: true)
    @State private var currentTemperatureState = TemperatureState(value: 0)
    @State private var currentHumidityState = HumidityState(value: 0)
    
    @State private var isDataListeningEnabled = false
    
    @State private var receivedRawData = ""
    
    var body: some View {
        List {
            Button {
                withAnimation {
                    if focusedSensor == .illuminance {
                        focusedSensor = nil
                        listener.cancel()
                        isDataListeningEnabled = false
                    } else {
                        focusedSensor = .illuminance
                        serverConnectAction()
                        isDataListeningEnabled = true

                    }
                }
            } label: {
                IlluminanceSensorListCell
            }
            .listItemTint(focusedSensor == .illuminance ? .white : nil)
             
            Button {
                withAnimation {
                    
                    if focusedSensor == .dht {
                        focusedSensor = nil
                        listener.cancel()
                        isDataListeningEnabled = false

                    } else {
                        focusedSensor = .dht
                        serverConnectAction()
                        isDataListeningEnabled = true

                    }
                }
            } label: {
                DHTSensorListCell
            }
            .listItemTint(focusedSensor == .dht ? .white : nil)
        }
        .listStyle(.carousel)
        
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isOptionsModalPresented = true
                } label: {
                    Label("Options", systemImage: "slider.horizontal.3")
                }
                .tint(.blue)
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $isOptionsModalPresented) {
            QuickSensorOptionsModal(isPresented: $isOptionsModalPresented,
                                    options: $options)
        }
        
        .navigationTitle("QuickSensor")
        
    }
    
    private var IlluminanceSensorListCell: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Illuminance Sensor")
                    .bold()
                    .padding(.vertical)
                    .foregroundColor(focusedSensor == .illuminance ? .black : nil)
                
                Spacer()
                Image(systemName: focusedSensor == .illuminance ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title3)
                    .imageScale(.large)
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.monochrome)
            }
            
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(focusedSensor == .illuminance ? lightBulbForegroundColor() : nil)
                    .symbolRenderingMode(.multicolor)
                Spacer()
                
                if isDataListeningEnabled && focusedSensor == .illuminance {
                    Text(currentIlluminanceSensorState.isIlluminated ? "Light" : "Dark")
                        .foregroundColor(.black)
                } else {
                    Text("--")
                }
            }
            .font(.largeTitle)
            .padding(.bottom)
        }
        .symbolRenderingMode(.hierarchical)
        
    }
    
    private var DHTSensorListCell: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("DHT Sensor")
                    .bold()
                    .foregroundColor(focusedSensor == .dht ? .black : nil)
                
                Spacer()
                
                Image(systemName: focusedSensor == .dht ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title3)
                    .imageScale(.large)
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.monochrome)
                
            }
            .padding(.vertical)
            
            HStack {
                Image(systemName: "thermometer.medium")
                    .foregroundColor(focusedSensor == .dht ? .red : nil)
                Spacer()
                
                if isDataListeningEnabled && focusedSensor == .dht {
                    Text("\(NSNumber(value: Double(String(format:"%.1f", currentTemperatureState.value))!))°C")
                        .foregroundColor(.black)
                } else {
                    Text("--°C")
                }
            }
            .font(.largeTitle)
            .padding(.bottom)
            Divider()
                .foregroundColor(.red)
            HStack {
                Image(systemName: "humidity")
                    .foregroundColor(focusedSensor == .dht ? .blue : nil)
                    .padding(.vertical)
                Spacer()
                if isDataListeningEnabled && focusedSensor == .dht {
                    Text("\(NSNumber(value: Double(String(format:"%.1f", currentHumidityState.value))!))%")
                        .foregroundColor(.black)
                } else {
                    Text("--%")
                }
            }
            .font(.largeTitle)
            .padding(.vertical)
        }
        .symbolRenderingMode(.hierarchical)
    }
    
    //Functions
    
    private func lightBulbForegroundColor() -> Color {
        if currentIlluminanceSensorState.isIlluminated {
            return .yellow
        } else {
            return .indigo
        }
    }
    
    // Network Support
    //  服务端开始监听并处理连接
    private func serverConnectAction() {
        
        listener = try! NWListener(using: .tcp, on: NWEndpoint.Port(options.port)!)
        
        // 处理新加入的连接
        listener.newConnectionHandler = { newConnection in
            newConnection.start(queue: serverQueue)
            self.receive(on: newConnection)
            print(newConnection.endpoint)
        }
        
        // 监听连接状态
        listener.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("Listening on port: \(String(describing: listener.port))")
                self.isDataListeningEnabled = true
            case .failed(let error):
                print("Listener failed with error: \(error)")
            case .setup:
                print("state setup")
            case .cancelled:
                print("state cancelled")
                listener.cancel()
                
            default:
                break
            }
        }
        
        listener.start(queue: serverQueue)
    }
    
    //  服务端接收来自 connection 的数据，并通过解析存入数据库、更新视图上下文
    private func receive(on connection: NWConnection) {
        
        connection.receive(minimumIncompleteLength: .min, maximumLength: .max) { (content, context, isComplete, error) in
            if content != nil {
                let data = String(data: content ?? "".data(using: .utf8)!, encoding: .utf8)
                print("received: \(data!)")
                
                if (data!.isIlluminanceRawData() && focusedSensor == .illuminance) || (data!.isBinary()) {
                    receivedRawData = data!
                    withAnimation {
                        sensorDataReceiveAction()
                    }
                }
                
                
                if isComplete {
                    //关闭资源
                    listener.cancel()
                    return
                    
                }
                
                if error == nil && isDataListeningEnabled {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + TimeInterval(1)) {
                        self.receive(on: connection)
                    }
                }
            }
        }
    }
    
    private func sensorDataReceiveAction() {
        if focusedSensor == .illuminance {
            currentIlluminanceSensorState = IlluminanceSensorState(isIlluminated: illuminanceParsedFrom(receivedRawData))
        } else if focusedSensor == .dht {
            currentTemperatureState.value = organizedData(from: receivedRawData).temperature.value
            currentHumidityState.value = organizedData(from: receivedRawData).humidity.value
        }
    }
    
}

struct NavigationListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuickSensorListView()
        }
    }
}
