//
//  SidebarNavigationList.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/24.
//

import SwiftUI

struct SidebarNavigationList: View {
    @EnvironmentObject var store: NavigationStore
    
#if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
#endif
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DHTData.timestamp, ascending: true)],
        animation: .default) private var dhtItems: FetchedResults<DHTData>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \IlluminanceData.timestamp, ascending: true)],
        animation: .default) private var illuminanceItems: FetchedResults<IlluminanceData>
    
    
    var body: some View {
        List(selection: $store.selection) {
            NavigationLink(value: 0) {
                IlluminanceSensor
            }
            
            NavigationLink(value: 1) {
                DHTSensor
            }
        }
        .navigationTitle("QuickSensor")
        .listStyle(.sidebar)
    }
    
    var DHTSensor: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("DHT Sensor")
            HStack {
                HStack(spacing: 2) {
                    HStack(spacing: 0) {
                        Image(systemName: "thermometer.medium")
#if os(iOS)
                            .foregroundColor(store.selection == 1 ? horizontalSizeClass == .compact ? .red : .white : .red)
#else
                            .foregroundColor(store.selection == 1 ? .white : .red)
#endif
                        Text(dhtItems.isEmpty ? "--" : "\(NSNumber(value: Double(dhtItems.last!.temperature) / 10))°")
                            .frame(width: 42)
#if os(macOS)
                            .foregroundColor(store.selection == 1 ? .white : nil)
#endif
                    }
                    
                    HStack(spacing: 0) {
                        Image(systemName: "humidity")
#if os(iOS)
                            .foregroundColor(store.selection == 1 ? horizontalSizeClass == .compact ? .blue : .white : .blue)
#else
                            .foregroundColor(store.selection == 1 ? .white : .blue)
#endif
                        Text(dhtItems.isEmpty ? "--" : "\(NSNumber(value: Double(dhtItems.last!.humidity) / 10))%")
                            .frame(width: 42)
#if os(macOS)
                            .foregroundColor(store.selection == 1 ? .white : nil)
#endif
                    }
                }
                .font(.footnote)
            }
        }
    }
    
    var IlluminanceSensor: some View {
        VStack(alignment: .leading) {
            Text("Illuminance Sensor")
            
            HStack {
                
                if illuminanceItems.isEmpty {
                    Image(systemName: "lightbulb")
                        .symbolRenderingMode(.multicolor)
                    Text("--")
                } else {
                    
                    Image(systemName: illuminanceItems.last!.isIlluminated ? "lightbulb.fill" : "lightbulb")
                        .foregroundColor(illuminanceItems.last!.isIlluminated ? .yellow : nil)
                        .symbolRenderingMode(.multicolor)
                    Text(illuminanceItems.last!.isIlluminated ? "Light" : "Dark")
                }
            }
            .font(.footnote)
        }
    }
}

struct SidebarNavigationList_Previews: PreviewProvider {
    static var previews: some View {
        SidebarNavigationList()
    }
}
