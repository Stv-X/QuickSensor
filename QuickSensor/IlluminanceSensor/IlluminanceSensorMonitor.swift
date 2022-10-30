//
//  IlluminanceSensorMonitor.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/27.
//

import SwiftUI
import Charts

struct IlluminanceSensorMonitor: View {
    
    @State private var illuminanceSensorState = IlluminanceSensorState(isIlluminated: false)
    @State private var illuminationRecords: [IlluminationRecord] = []
    @State private var illuminationIntervalRecords: [IlluminationIntervalRecord] = []
    @State private var timestampOfChartBeganPlotting = Date()
    
    @State private var isAutoRefreshEnabled = false
    @State private var isOptionsPopoverPresented = false
    
    private let autoRefreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
            VStack {
                HStack {
                    VStack {
                        lightbulbSymbol
                        Text(illuminanceSensorState.isIlluminated ? "Illuminated" : "Not Illuminated")
                            .font(.system(.title, design: .rounded))
                            .lineLimit(1)
#if os(iOS)
                            .bold()
                            .frame(width: 140)
#endif
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Chart(illuminationIntervalRecords) { record in
                        
                        BarMark(
                            xStart: record.start.timeIntervalSince(timestampOfChartBeganPlotting) * 25,
                            xEnd: record.end.timeIntervalSince(timestampOfChartBeganPlotting) * 25,
                            y: .value("State", record.state.rawValue.capitalized)
                        )
                        .foregroundStyle(barMarkColor(record: record))
                        
                    }
                    
                    .chartXScale(domain: timestampOfChartBeganPlotting.timeIntervalSince(timestampOfChartBeganPlotting)...timestampOfChartBeganPlotting.addingTimeInterval(20).timeIntervalSince(timestampOfChartBeganPlotting))
                    
                    .frame(width: 500, height: 100)
                    .padding()
                }
                
                Divider()
                
                DisclosureGroup("Details") {
                    DetailsGroup
                        .padding(.vertical)
                }
                .padding(.horizontal)
                Spacer()
                
            }
        
            .frame(minWidth: 640, minHeight: 300)
        
        .toolbar {
            ToolbarItem(placement: .navigation) {
                SensorDataAutoRefreshButton
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                SensorDataRefreshButton
                OptionsButton
            }
        }
        
        .onAppear {
            onAppearAction()
        }
        
        .onReceive(autoRefreshTimer) { _ in
            if isAutoRefreshEnabled {
                withAnimation {
                    sensorRefreshAction()
                }
            }
        }
    }
    
    // 􀛭
    var lightbulbSymbol: some View {
        Image(systemName: illuminanceSensorState.isIlluminated ? "lightbulb.fill" : "lightbulb")
            .foregroundColor(illuminanceSensorState.isIlluminated ? .yellow : .gray)
            .symbolRenderingMode(.multicolor)
            .font(.largeTitle)
            .imageScale(.large)
            .padding()
    }
    
    //MARK: Toolbar Buttons
    
    // 􀊃 Auto Refresh
    var SensorDataAutoRefreshButton: some View {
        Button {
            isAutoRefreshEnabled.toggle()
        } label: {
            Label(isAutoRefreshEnabled ? "Stop" : "Auto",
                  systemImage: isAutoRefreshEnabled ? "stop.fill" : "play.fill")
        }
    }
    
    // 􀈄 Manual Refresh
    private var SensorDataRefreshButton: some View {
        Button {
            withAnimation {
                
            }
        } label: {
            Label("Refresh", systemImage: "square.and.arrow.down")
        }
        .disabled(isAutoRefreshEnabled)
    }
    
    // 􀌆 Options
    private var OptionsButton: some View {
        Button {
            isOptionsPopoverPresented.toggle()
        } label: {
            Label("Options", systemImage: "slider.horizontal.3")
        }
        .disabled(isAutoRefreshEnabled)
    }
    
    //MARK: Detaild Group
    var DetailsGroup: some View {
        GroupBox {
            Text("0101002030101011")
                .font(.system(.body, design: .monospaced))
#if os(macOS)
                .frame(width: 394)
#endif
                .contextMenu {
                    Button {
                        copyToClipBoard(textToCopy: "0101002030101011")
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            
        } label: {
            Text("Raw Data")
        }
    }
    
    private func onAppearAction() {
        illuminanceSensorState.isIlluminated = randomIlluminance()
        if illuminationRecords.isEmpty {
            illuminationRecords.append(IlluminationRecord(isIlluminated: illuminanceSensorState.isIlluminated,
                                                          timestamp: Date()))
            
            illuminationIntervalRecords.append(IlluminationIntervalRecord(state:
                                                                            illuminanceSensorState.isIlluminated ? .isIlluminated : .isNotIlluminated,
                                                                          start: illuminationRecords.first!.timestamp,
                                                                          end: illuminationIntervalRecords.isEmpty ? illuminationRecords.last!.timestamp : illuminationRecords.last!.timestamp))
        }
    }
    
    private func sensorRefreshAction() {
        illuminanceSensorState.isIlluminated = randomIlluminance()
        
        let lastIlluminationRecord = illuminationRecords.last!
        
        illuminationRecords.append(IlluminationRecord(isIlluminated: illuminanceSensorState.isIlluminated, timestamp: Date()))
        
        if illuminationRecords.last!.isIlluminated == lastIlluminationRecord.isIlluminated {
            illuminationIntervalRecords[illuminationIntervalRecords.count - 1].end = illuminationRecords.last!.timestamp
        } else {
            illuminationIntervalRecords.append(IlluminationIntervalRecord(state: illuminanceSensorState.isIlluminated ? .isIlluminated : .isNotIlluminated, start: lastIlluminationRecord.timestamp, end: illuminationRecords.last!.timestamp))
            
            if illuminationIntervalRecords.first!.start.formatted(date: .omitted, time: .standard) == illuminationIntervalRecords.first!.end.formatted(date: .omitted, time: .standard) {
                illuminationIntervalRecords.remove(at: 0)
            }
            
        }
        
        if illuminationRecords.count == 22 {
            timestampOfChartBeganPlotting.addTimeInterval(1)
            illuminationRecords.remove(at: 0)
            
            if illuminationIntervalRecords.first!.end.timeIntervalSince(illuminationIntervalRecords.first!.start) <= 1.9 {
                illuminationIntervalRecords.remove(at: 0)
            } else {
                illuminationIntervalRecords[0].start = timestampOfChartBeganPlotting
            }
            
        }
        
    }
    
    private func barMarkColor(record: IlluminationIntervalRecord) -> Color {
        if record.state == .isIlluminated {
            return .yellow
            
        } else {
            return .indigo
        }
    }
    
    private func randomIlluminance() -> Bool {
        let seed = Int.random(in: 0...1)
        
        if seed == 0 {
            return false
        } else {
            return true
        }
        
    }
    
}

struct IlluminanceSensorMonitor_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            IlluminanceSensorMonitor()
        }
    }
}
