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
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \IlluminanceData.timestamp, ascending: true)],
        animation: .default) private var items: FetchedResults<IlluminanceData>
    
    @State private var currentIlluminanceState = IlluminanceSensorState()
    @State private var illuminanceRecords: [IlluminanceRecord] = []
    @State private var illuminanceIntervalRecords: [IlluminanceIntervalRecord] = []
    @State private var plotTime = Date()
    
    @State private var receivedRawData = ""
    
    @State public var options = SensorMonitorOptions()
    
    @State private var isOptionsModalPresented = false
    @State private var isDataListeningEnabled = false
    
    @State private var isFirstPlot = true
    
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    lightbulbSymbol
                    Text(currentIlluminanceState.isIlluminated ? "Illuminated" : "Not Illuminated")
                        .font(.system(.title, design: .rounded))
                        .lineLimit(1)
                        .frame(width: 140)
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
                    .frame(width: 240, height: 120)
                    .padding(.horizontal)
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
                OptionsButton
            }
        }
        
        .onAppear {
            onAppearAction()
        }
        
#if os(iOS)
        .toolbarRole(.browser)
        
        .sheet(isPresented: $isOptionsModalPresented) {
            NavigationStack {
                SensorMonitorOptionsModal(isPresented: $isOptionsModalPresented,
                                          options: $options)
                .navigationTitle("Options")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
#endif
        
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
                if illuminanceRecords.isEmpty {
                    isFirstPlot = true
                }
                listener.cancel()
                isDataListeningEnabled = false
            } else {
                if isFirstPlot {
                    plotTime = Date()
                    isFirstPlot = false
                }
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
        
        if illuminanceIntervalRecords.isEmpty {
            illuminanceIntervalRecords.append(IlluminanceIntervalRecord(state: IlluminanceSensorState(isIlluminated: true),
                                                                        start: 0,
                                                                        end: 0,
                                                                        startTime: plotTime,
                                                                        endTime: plotTime))
            
            illuminanceIntervalRecords.append(IlluminanceIntervalRecord(state: IlluminanceSensorState(isIlluminated: false),
                                                                        start: 0,
                                                                        end: 0,
                                                                        startTime: plotTime,
                                                                        endTime: plotTime))
        }
    }
    
    // Core Data Support
    // 将内容持久化存储到本地数据库中
    private func addItem() {
        let newItem = IlluminanceData(context: viewContext)
        newItem.timestamp = illuminanceRecords.last!.timestamp
        newItem.isIlluminated = currentIlluminanceState.isIlluminated
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
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
                if error == .posix(.EADDRINUSE) {
                    listener.cancel()
                    isDataListeningEnabled = false
                }
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
                let data = content!.hexadecimal()
                print("received: \(data)")
                
                if data.isIlluminanceRawData() {
                    receivedRawData = data
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
        if illuminanceParsedFrom(receivedRawData) == nil {
            print("NIL")
            return
        }
        
        currentIlluminanceState = IlluminanceSensorState(isIlluminated: illuminanceParsedFrom(receivedRawData)!)
        
        let timestamp = Date()
        
        illuminanceRecords.append(IlluminanceRecord(state: currentIlluminanceState, timestamp: timestamp))
        
        if illuminanceIntervalRecords.count - 2 == 0 {
            illuminanceIntervalRecords.append(IlluminanceIntervalRecord(state: currentIlluminanceState,
                                                                        start: 0,
                                                                        end: plotTime.distance(to: timestamp),
                                                                        startTime: plotTime,
                                                                        endTime: timestamp))
        } else {
            illuminanceIntervalRecords[illuminanceIntervalRecords.count - 1].end = plotTime.distance(to: timestamp)
            illuminanceIntervalRecords[illuminanceIntervalRecords.count - 1].endTime = timestamp
            
            if illuminanceIntervalRecords.last!.state.isIlluminated != currentIlluminanceState.isIlluminated {
                
                illuminanceIntervalRecords.append(IlluminanceIntervalRecord(state: currentIlluminanceState,
                                                                            start: plotTime.distance(to: timestamp),
                                                                            end: plotTime.distance(to: Date()),
                                                                            startTime: timestamp,
                                                                            endTime: Date()))
            }
        }
        
        addItem()
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
