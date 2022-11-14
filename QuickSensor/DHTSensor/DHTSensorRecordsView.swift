//
//  DHTSensorRecordsView.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/23.
//

import SwiftUI

struct DHTSensorRecordsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DHTData.timestamp, ascending: true)],
        animation: .default) private var items: FetchedResults<DHTData>
    
    var body: some View {
        Table {
            
#if os(iOS)
            TableColumn("Timestamp") {
                Text("\(($0.timestamp?.formatted(date: .numeric, time: .standard))!)")
            }
            .width(min: 180)
#endif
            
            
            
            TableColumn("Temperature") {
                ProgressView("\(NSNumber(value: Double($0.temperature) / 10))°",
                             value: Double($0.temperature) / 10 + 20,
                             total: 100)
                .progressViewStyle(TemperatureProgressViewStyle())
                
            }
            .width(min: 80)
            
            TableColumn("Humidity") {
                ProgressView("\(NSNumber(value: Double($0.humidity) / 10))%",
                             value: Double($0.humidity) / 10,
                             total: 100)
                
                .progressViewStyle(HumidityProgressViewStyle())
            }
            .width(min: 60)
            
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

struct HumidityProgressViewStyle: ProgressViewStyle {
    
    let backgroundColor: Color
    init(backgroundColor: Color = .secondary.opacity(0.2)) {
        self.backgroundColor = backgroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 6) {
                configuration.label
                ZStack(alignment:.topLeading){
                    backgroundColor
                    Capsule(style: .continuous)
                        .fill(LinearGradient(colors: [.mint, .cyan, .indigo],
                                             startPoint: .leading,
                                             endPoint: UnitPoint(x: abs(UnitPoint.trailing.x - UnitPoint.leading.x) / configuration.fractionCompleted! , y: UnitPoint.trailing.y)))
                        .frame(width:proxy.size.width * CGFloat(configuration.fractionCompleted ?? 0.0))
                }
                .clipShape(Capsule(style: .continuous))
                .frame(height: 6)
            }
        }
        .frame(height: 36)
    }
}

struct TemperatureProgressViewStyle: ProgressViewStyle {
    
    let backgroundColor: Color
    init(backgroundColor: Color = .secondary.opacity(0.2)) {
        self.backgroundColor = backgroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 6) {
                configuration.label
                ZStack(alignment:.topLeading){
                    backgroundColor
                    Capsule(style: .continuous)
                        .fill(LinearGradient(colors: [.teal, .yellow, .red],
                                             startPoint: .leading,
                                             endPoint: UnitPoint(x: abs(UnitPoint.trailing.x - UnitPoint.leading.x) / configuration.fractionCompleted! , y: UnitPoint.trailing.y)))
                    
                        .frame(width: proxy.size.width * CGFloat(configuration.fractionCompleted ?? 0.0))
                }
                .clipShape(Capsule(style: .continuous))
                .frame(height: 6)
            }
        }
        .frame(height: 36)
    }
}

struct DHTRecordsView_Previews: PreviewProvider {
    static var previews: some View {
        DHTSensorRecordsView()
    }
}
