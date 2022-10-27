//
//  QuickSensorApp.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/23.
//

import SwiftUI

@main
struct QuickSensorApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
#if os(macOS)
                .frame(minWidth: 680)
#endif
        }
    }
}
