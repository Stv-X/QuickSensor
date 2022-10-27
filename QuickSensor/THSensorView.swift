//
//  THSensorView.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/24.
//

import SwiftUI

struct THSensorView: View {
    @EnvironmentObject var store: NavigationStore
    var body: some View {
        
        TabView {
            NavigationStack {
                THSensorMonitor()
            }
            .tabItem {
                Label("T&H", systemImage: "thermometer.medium")
            }
            
            THSensorRecords()
                .tabItem {
                    Label("Records", systemImage: "list.bullet.clipboard")
                }
        }
        .navigationTitle("T&H Sensor")
        #if os(macOS)
        .padding()
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct THSensorView_Previews: PreviewProvider {
    static var previews: some View {
        THSensorView()
    }
}
