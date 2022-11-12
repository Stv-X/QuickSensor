//
//  QuickSensorListView.swift
//  QuickSensorWatch Watch App
//
//  Created by 徐嗣苗 on 2022/11/12.
//

import SwiftUI

enum SensorCategory {
    case illuminance, dht
}

struct QuickSensorListView: View {
    @State private var focusedSensor: SensorCategory? = nil
    @State private var isOptionsModalPresented = false
    @State public var options = SensorMonitorOptions()
    var body: some View {
        List {
            Button {
                withAnimation {
                    if focusedSensor == .illuminance {
                        focusedSensor = nil
                    } else {
                        focusedSensor = .illuminance
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
                    } else {
                        focusedSensor = .dht
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
                    .font(.largeTitle)
                    .foregroundColor(focusedSensor == .illuminance ? lightBulbForegroundColor() : nil)
                    .symbolRenderingMode(.multicolor)
                Spacer()
            }
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
                    .font(.largeTitle)
                Spacer()
            }
            .padding(.bottom)
            Divider()
                .foregroundColor(.red)
            HStack {
                Image(systemName: "humidity")
                    .foregroundColor(focusedSensor == .dht ? .blue : nil)
                    .font(.largeTitle)
                    .padding(.vertical)
                Spacer()
            }
            .padding(.vertical)
        }
        .symbolRenderingMode(.hierarchical)
    }
    
    //Functions
    
    private func lightBulbForegroundColor() -> Color {
        return .yellow
    }
    
    
}

struct NavigationListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuickSensorListView()
        }
    }
}
