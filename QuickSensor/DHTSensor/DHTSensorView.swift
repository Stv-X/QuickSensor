//
//  DHTSensorView.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/24.
//

import SwiftUI

struct DHTSensorView: View {
    @EnvironmentObject var store: NavigationStore
    var body: some View {
        
        TabView {
            NavigationStack {
                DHTSensorMonitor()
            }
            .tabItem {
                Label("DHT", systemImage: "thermometer.medium")
            }
            
            DHTSensorRecordsView()
                .tabItem {
                    Label("Records", systemImage: "list.bullet.clipboard")
                }
        }
        .navigationTitle("DHT Sensor")
#if os(macOS)
        .padding()
#else
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

struct DHTSensorView_Previews: PreviewProvider {
    static var previews: some View {
        DHTSensorView()
    }
}
