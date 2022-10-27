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
        sortDescriptors: [NSSortDescriptor(keyPath: \THData.timestamp, ascending: true)],
        animation: .default)
    
    private var items: FetchedResults<THData>
    
    
    var body: some View {
        List(selection: $store.selection) {
            NavigationLink(value: 0) {
                THSensor
            }
            
            NavigationLink(value: 1) {
                IlluminanceSensor
            }
        }
        .navigationTitle("QuickSensor")
        .listStyle(.sidebar)
    }
    
    var THSensor: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("T&H Sensor")
            HStack {
                HStack(spacing: 2) {
                    HStack(spacing: 0) {
                        Image(systemName: "thermometer.medium")
#if os(iOS)
                            .foregroundColor(store.selection == 0 ? horizontalSizeClass == .compact ? .red : .white : .red)
#else
                            .foregroundColor(store.selection == 0 ? .white : .red)
#endif
                        Text(items.isEmpty ? "--" : "\(NSNumber(value: Double(items.last!.temperature) / 10))°")
                            .frame(width: 42)
#if os(macOS)
                            .foregroundColor(store.selection == 0 ? .white : nil)
#endif
                    }
                    
                    HStack(spacing: 0) {
                        Image(systemName: "humidity")
#if os(iOS)
                            .foregroundColor(store.selection == 0 ? horizontalSizeClass == .compact ? .blue : .white : .blue)
#else
                            .foregroundColor(store.selection == 0 ? .white : .blue)
#endif
                        Text(items.isEmpty ? "--" : "\(NSNumber(value: Double(items.last!.humidity) / 10))%")
                            .frame(width: 42)
#if os(macOS)
                            .foregroundColor(store.selection == 0 ? .white : nil)
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
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .symbolRenderingMode(.multicolor)
                Text("Illuminated")
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
