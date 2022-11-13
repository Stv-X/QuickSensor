//
//  IlluminanceSensorMonitor.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/27.
//

import SwiftUI
import Charts
import Network

struct IlluminanceSensorMonitor: View {
    
    @State private var currentIlluminanceState = IlluminanceSensorState()
    @State private var illuminanceRecords: [IlluminanceRecord] = []
    @State private var illuminanceIntervalRecords: [IlluminanceIntervalRecord] = []
    @State private var timestampOfChartBeganPlotting = Date()
    
    @State private var receivedRawData = ""
    
    @State public var options = SensorMonitorOptions()
    
    @State private var isOptionsModalPresented = false
    @State private var isDataListeningEnabled = false

    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    lightbulbSymbol
                    Text(currentIlluminanceState.isIlluminated ? "Illuminated" : "Not Illuminated")
                        .font(.system(.title, design: .rounded))
                        .lineLimit(1)
#if os(iOS)
                        .bold()
                        .frame(width: 140)
                        .padding(.horizontal)
#endif
                }
                .padding(.horizontal)
                
                Spacer()
                
                IlluminanceChart
                
                #if os(iOS)
                    .frame(width: 280, height: 120)
                #else
                .frame(width: 500, height: 100)
                .padding()
                #endif
                
            }
            .padding(.horizontal)
            
            Divider()
            
            DisclosureGroup("Details") {
                HStack {
                    DetailsGroup
                        .padding(.vertical)
                    Spacer()
                }
            }
            .padding(.horizontal)
            Spacer()
            
        }
        #if os(macOS)
        .frame(minWidth: 640, minHeight: 300)
        #endif
        
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
    }
    
    // 􀛭
    var lightbulbSymbol: some View {
        Image(systemName: currentIlluminanceState.isIlluminated ? "lightbulb.fill" : "lightbulb")
            .foregroundColor(currentIlluminanceState.isIlluminated ? .yellow : .gray)
            .symbolRenderingMode(.multicolor)
            .font(.largeTitle)
            .imageScale(.large)
            .padding()
    }
    
    //MARK: Toolbar Buttons
    
    // 􀊃 Auto Refresh
    var SensorDataAutoRefreshButton: some View {
        Button {
            if isDataListeningEnabled {
                listener.cancel()
                isDataListeningEnabled = false
            } else {
                serverConnectAction()
                isDataListeningEnabled = true
            }
        } label: {
            Label(isDataListeningEnabled ? "Stop" : "Auto",
                  systemImage: isDataListeningEnabled ? "stop.fill" : "play.fill")
        }
    }
    
    // 􀈄 Manual Refresh
    private var SensorDataRefreshButton: some View {
        Button {
            withAnimation {
                sensorDataReceiveAction()
                
            }
        } label: {
            Label("Refresh", systemImage: "square.and.arrow.down")
        }
        .disabled(isDataListeningEnabled)
    }
    
    // 􀌆 Options
    private var OptionsButton: some View {
        Button {
            isOptionsModalPresented.toggle()
        } label: {
            Label("Options", systemImage: "slider.horizontal.3")
        }
        .disabled(isDataListeningEnabled)
#if os(macOS)
        
        .popover(isPresented: $isOptionsModalPresented) {
            
            SensorMonitorOptionsModal(isPresented: $isOptionsModalPresented,
                                      options: $options)
            
        }
        
        
#endif
    }
    
    private var IlluminanceChart: some View {
        Chart(illuminanceIntervalRecords) { record in
            
            BarMark(
                xStart: .value("Start Time", record.start),
                xEnd: .value("End Time", record.end),
                y: .value("Record", record.stateStr)
            )
            .foregroundStyle(record.state.isIlluminated ? .yellow : .indigo)
            
        }
        
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel("""
                            \(value.as(PlottableMeasurement.self)!
                                .measurement
                                .converted(to: .seconds),
                            format: .measurement(
                                width: .narrow,
                                numberFormatStyle: .number.precision(
                                    .fractionLength(0))
                                )
                            )
                            """)
                
            }
        }
    }
    
    //MARK: Detaild Group
    var DetailsGroup: some View {
        GroupBox {
            Text(receivedRawData)
                .font(.system(.body, design: .monospaced))
#if os(macOS)
                .frame(width: 394)
#endif
                .contextMenu {
                    Button {
                        copyToClipBoard(textToCopy: receivedRawData)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            
        } label: {
            Text("Raw Data")
        }
    }
    
    private func onAppearAction() {
        illuminanceIntervalRecords.append(IlluminanceIntervalRecord(state: IlluminanceSensorState(isIlluminated: true),
                                                                    start: 0,
                                                                    end: 0,
                                                                    startTime: timestampOfChartBeganPlotting,
                                                                    endTime: timestampOfChartBeganPlotting))
        
        illuminanceIntervalRecords.append(IlluminanceIntervalRecord(state: IlluminanceSensorState(isIlluminated: false),
                                                                    start: 0,
                                                                    end: 0,
                                                                    startTime: timestampOfChartBeganPlotting,
                                                                    endTime: timestampOfChartBeganPlotting))
    }
    
    // Network Support
    //  服务端开始监听并处理连接
    private func serverConnectAction() {
        
        listener = try! NWListener(using: .tcp, on: NWEndpoint.Port(options.port)!)
        
        // 处理新加入的连接
        listener.newConnectionHandler = { newConnection in
            newConnection.start(queue: serverQueue)
            self.receive(on: newConnection)
            print(newConnection.endpoint)
        }
        
        // 监听连接状态
        listener.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("Listening on port: \(String(describing: listener.port))")
                self.isDataListeningEnabled = true
            case .failed(let error):
                print("Listener failed with error: \(error)")
            case .setup:
                print("state setup")
            case .cancelled:
                print("state cancelled")
                listener.cancel()
                
            default:
                break
            }
        }
        
        listener.start(queue: serverQueue)
    }
    
    //  服务端接收来自 connection 的数据，并通过解析存入数据库、更新视图上下文
    private func receive(on connection: NWConnection) {
        
        connection.receive(minimumIncompleteLength: .min, maximumLength: .max) { (content, context, isComplete, error) in
            if content != nil {
                let data = String(data: content ?? "".data(using: .utf8)!, encoding: .utf8)
                print("received: \(data!)")
                
                if data!.isIlluminanceRawData() {
                    receivedRawData = data!
                    withAnimation {
                        sensorDataReceiveAction()
                    }
                }
                
                
                if isComplete {
                    //关闭资源
                    listener.cancel()
                    return
                    
                }
                
                if error == nil && isDataListeningEnabled {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + TimeInterval(1)) {
                        self.receive(on: connection)
                    }
                }
            }
        }
    }
    
    
    private func sensorDataReceiveAction() {
        
        currentIlluminanceState = IlluminanceSensorState(isIlluminated: illuminanceParsedFrom(receivedRawData))
        
        let timestamp = Date()
        
        illuminanceRecords.append(IlluminanceRecord(state: currentIlluminanceState, timestamp: timestamp))
        
        if illuminanceIntervalRecords.count - 2 == 0 {
            illuminanceIntervalRecords.append(IlluminanceIntervalRecord(state: currentIlluminanceState,
                                                                        start: 0,
                                                                        end: timestampOfChartBeganPlotting.distance(to: timestamp),
                                                                        startTime: timestampOfChartBeganPlotting,
                                                                        endTime: timestamp))
        } else {
            illuminanceIntervalRecords[illuminanceIntervalRecords.count - 1].end = timestampOfChartBeganPlotting.distance(to: timestamp)
            illuminanceIntervalRecords[illuminanceIntervalRecords.count - 1].endTime = timestamp
            
            if illuminanceIntervalRecords.last!.state.isIlluminated != currentIlluminanceState.isIlluminated {
                
                illuminanceIntervalRecords.append(IlluminanceIntervalRecord(state: currentIlluminanceState,
                                                                            start: timestampOfChartBeganPlotting.distance(to: timestamp),
                                                                            end: timestampOfChartBeganPlotting.distance(to: Date()),
                                                                            startTime: timestamp,
                                                                            endTime: Date()))
            }
        }
        
        
    }
    
    private func barMarkColor(record: IlluminanceIntervalRecord) -> Color {
        if record.state.isIlluminated {
            return .yellow
            
        } else {
            return .indigo
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
