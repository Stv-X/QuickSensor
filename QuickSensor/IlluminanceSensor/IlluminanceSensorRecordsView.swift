//
//  IlluminanceSensorRecordsView.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/11/14.
//

import SwiftUI

struct IlluminanceSensorRecordsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \IlluminanceData.timestamp, ascending: true)],
        animation: .default) private var items: FetchedResults<IlluminanceData>
    
    var body: some View {
        Table {
            
#if os(iOS)
            TableColumn("Timestamp") {
                Text("\(($0.timestamp?.formatted(date: .numeric, time: .standard))!)")
            }
            .width(min: 180)
#endif
            
            
            
            TableColumn("Illuminance State") {
                if $0.isIlluminated {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .symbolRenderingMode(.multicolor)
                        Text("Light")
                    }
                } else {
                    HStack {
                        Image(systemName: "lightbulb")
                        Text("Dark")
                    }
                }
            }
            .width(min: 80)
            
            
#if os(macOS)
            TableColumn("Timestamp") {
                Text("\(($0.timestamp?.formatted(date: .numeric, time: .standard))!)")
            }
            .width(min: 180)
#endif
            
        } rows: {
            ForEach(items.reversed()) {
                TableRow($0)
            }
        }
        .frame(minWidth: 340)
    }
}

struct IlluminanceSensorRecordsView_Previews: PreviewProvider {
    static var previews: some View {
        IlluminanceSensorRecordsView()
    }
}
