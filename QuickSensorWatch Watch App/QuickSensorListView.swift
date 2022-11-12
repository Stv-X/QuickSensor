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
    var body: some View {
        List {
            IlluminanceSensorListCell
                .onTapGesture {
                    withAnimation {
                        if focusedSensor == .illuminance {
                            focusedSensor = nil
                        } else {
                            focusedSensor = .illuminance
                        }
                    }
                }
            DHTSensorListCell
                .onTapGesture {
                    withAnimation {
                        if focusedSensor == .dht {
                            focusedSensor = nil
                        } else {
                            focusedSensor = .dht
                        }
                    }
                }
        }
        .listStyle(.carousel)
        .navigationTitle("QuickSensor")
    }
    
    private var IlluminanceSensorListCell: some View {
        VStack(alignment: .leading) {
            Text("Illuminance Sensor")
                .bold()
                .padding(.vertical)
            HStack {
                Image(systemName: "lightbulb")
                    .font(.largeTitle)
                Spacer()
            }
            .padding(.bottom)
        }
        .foregroundColor(focusedSensor == .illuminance ? .black : nil)
        .listItemTint(focusedSensor == .illuminance ? .white : nil)
    }
    
    private var DHTSensorListCell: some View {
        VStack(alignment: .leading) {
            Text("DHT Sensor")
                .bold()
                .padding(.vertical)
            HStack {
                Image(systemName: "thermometer.medium")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Spacer()
            }
            .padding(.bottom)
            Divider()
            HStack {
                Image(systemName: "humidity")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .padding(.vertical)
                Spacer()
            }
            .padding(.vertical)
        }
        .foregroundColor(focusedSensor == .dht ? .black : nil)
        .listItemTint(focusedSensor == .dht ? .white : nil)
    }
}

struct NavigationListView_Previews: PreviewProvider {
    static var previews: some View {
        QuickSensorListView()
    }
}
