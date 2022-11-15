//
//  IlluminanceSensorView.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/30.
//

import SwiftUI

struct IlluminanceSensorView: View {
    @EnvironmentObject var store: NavigationStore
    var body: some View {
        TabView {
            NavigationStack {
                IlluminanceSensorMonitor()
            }
            .tabItem {
                Label("Illuminance", systemImage: "lightbulb")
            }
            
            IlluminanceSensorRecordsView()
                .padding()
                .tabItem {
                    Label("Records", systemImage: "list.bullet.clipboard")
                }
        }
        .navigationTitle("Illuminance Sensor")
#if os(macOS)
        .padding()
#else
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

struct IlluminanceSensorView_Previews: PreviewProvider {
    static var previews: some View {
        IlluminanceSensorView()
    }
}
