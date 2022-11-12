//
//  QuickSensorListView.swift
//  QuickSensorWatch Watch App
//
//  Created by 徐嗣苗 on 2022/11/12.
//

import SwiftUI
import Network

enum SensorCategory {
    case illuminance, dht
}

struct QuickSensorListView: View {
    @State private var focusedSensor: SensorCategory? = nil
    @State private var isOptionsModalPresented = false
    @State public var options = SensorMonitorOptions()
    
    @State private var currentIlluminanceSensorState = IlluminanceSensorState(isIlluminated: true)
    @State private var currentTemperatureState = TemperatureState(value: 0)
    @State private var currentHumidityState = HumidityState(value: 0)
    
    @State private var isDataListeningEnabled = false
    
    var body: some View {
        List {
            Button {
                withAnimation {
                    
                    if focusedSensor == .illuminance {
                        focusedSensor = nil
                        isDataListeningEnabled = false
                    } else {
                        focusedSensor = .illuminance
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
                        isDataListeningEnabled = false

                    } else {
                        focusedSensor = .dht
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
    
    
}

struct NavigationListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuickSensorListView()
        }
    }
}
