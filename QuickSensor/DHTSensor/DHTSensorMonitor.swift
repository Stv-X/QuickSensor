//
//  DHTSensorMonitor.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/21.
//

import SwiftUI
import Charts
import Network

struct DHTSensorMonitor: View {
    
    @Environment(\.managedObjectContext) private var viewContext
#if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
#endif
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DHTData.timestamp, ascending: true)],
        animation: .default) private var items: FetchedResults<DHTData>
    
    @State private var receivedRawData = "0000001010010010000000010000110110100010"
    
    @State private var temperatureState = TemperatureState(value: 30)
    @State private var temperatureLevel = TemperatureLevel.medium
    @State private var temperatureRecords: [TemperatureRecord] = []
    
    @State private var humidityState = HumidityState(value: 23)
    @State private var humidityRecords: [HumidityRecord] = []
    
    @State private var isOptionsModalPresented = false
    @State private var isDataListeningEnabled = false
    
    @State private var isNetworkEndPointPortNumberInvalid = false
    
    @State private var isListeningHex = false
    
    @State public var options = SensorMonitorOptions()
    
    var body: some View {
        VStack {
            Grid(alignment: .leading,horizontalSpacing: 20, verticalSpacing: verticalSpacingForHorizontalSizeClass()) {
                GridRow {
                    HStack(spacing: 0) {
                        ThermometerSymbol
                            .onChange(of: temperatureState) { _ in
                                temperatureLevel = updatedTemperatureLevel()
                            }
                        
                        Text("\(NSNumber(value: Double(String(format:"%.1f", temperatureState.value))!))°C")
                            .font(.system(.largeTitle, design: .rounded))
                            .padding(.trailing)
#if os(iOS)
                            .bold()
                            .frame(width: 140)
#endif
                    }
                    
                    TemperatureChart
                        .padding(.trailing)
                        .frame(height: 80)
                }
#if os(iOS)
                .padding()
#else
                .padding(.vertical)
#endif
                
                Divider()
                GridRow {
                    HStack(spacing: 0) {
                        HumiditySymbol
                        
                        Text("\(NSNumber(value: Double(String(format:"%.1f", humidityState.value))!))%")
                            .font(.system(.largeTitle, design: .rounded))
                            .padding(.trailing)
#if os(iOS)
                            .bold()
                            .frame(width: 140)
#endif
                    }
                    HumidityChart
                        .padding(.trailing)
                        .frame(height: 80)
                }
#if os(iOS)
                .padding()
#else
                .padding(.vertical)
#endif
            }
#if os(iOS)
            .padding(.horizontal)
#endif
            
            Divider()
            
            DisclosureGroup("Details") {
                DHTSensorMonitorDetailsGroup(receivedRawData: $receivedRawData)
                    .padding(.vertical)
            }
            .padding(.horizontal)
            Spacer()
        }
        .frame(minWidth: 390, idealHeight: 300)
        
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
                                          options: $options,
                                          isHexToggleDisabled: .constant(false))
                .navigationTitle("Options")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
#endif
    }
    
    //MARK: Charts
    
    // Temperature Chart
    private var TemperatureChart: some View {
        Chart {
            ForEach(temperatureRecords) { record in
                BarMark(
                    x: .value("Timestamp", record.timestamp.formatted(date: .omitted, time: .standard)),
                    y: .value("Temperature", record.value)
                    
                )
                .foregroundStyle(temperatureChartBarMarkGradient(from: record))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(values: .stride(by: 20)) { value in
                AxisGridLine()
                AxisValueLabel(LocalizedStringKey(stringLiteral: (value.index == 2 || value.index == 4) ? "" : "\(value.index * 20 - 20)°C"))
            }
        }
        .chartYScale(domain: -20...80)
#if os(iOS)
        .chartYAxis(horizontalSizeClass == .compact ? .hidden : .visible)
#endif
    }
    
    // Humidity Chart
    private var HumidityChart: some View {
        Chart {
            ForEach(humidityRecords) { record in
                BarMark(
                    x: .value("Timestamp", record.timestamp.formatted(date: .omitted, time: .standard)),
                    y: .value("Humidity", record.value)
                )
                
                .foregroundStyle(humidityChartBarMarkGradient(from: record))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(values: .stride(by: 25)) { value in
                AxisGridLine()
                AxisValueLabel(LocalizedStringKey(stringLiteral: value.index % 2 == 0 ? "\(value.index * 25)%" : ""))
            }
        }
        .chartYScale(domain: 0...100)
#if os(iOS)
        .chartYAxis(horizontalSizeClass == .compact ? .hidden : .visible)
#endif
    }
    
    //MARK: Toolbar Buttons
    
    // 􀊃 Data Listening
    private var SensorDataAutoRefreshButton: some View {
        Button {
            if isDataListeningEnabled {
                listener.cancel()
                isDataListeningEnabled = false
            } else {
                serverConnectAction()
            }
            
        } label: {
            Label(isDataListeningEnabled ? "Stop" : "Auto",
                  systemImage: isDataListeningEnabled ? "stop.fill" : "play.fill")
        }
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
                                      options: $options,
                                      isHexToggleDisabled: .constant(false))
        }
#endif
    }
    
    // MARK: Dynamic Symbols
    
    // 􀇬 Temperature
    private var ThermometerSymbol: some View {
        thermometerImage()
            .imageScale(.large)
            .font(.largeTitle)
            .foregroundColor(.red)
            .symbolRenderingMode(.hierarchical)
            .padding()
    }
    
    // 􁃚 Humidity
    private var HumiditySymbol: some View {
        Image(systemName: "humidity")
            .imageScale(.large)
            .font(.largeTitle)
            .foregroundColor(.blue)
            .symbolRenderingMode(.hierarchical)
            .padding()
    }
    
    // MARK: Private Functions
    
    private func onAppearAction() {
        if !items.isEmpty {
            self.temperatureState = .init(value: Double(items.last!.temperature) / 10)
            self.humidityState = .init(value: Double(items.last!.humidity) / 10)
        } else {
            self.temperatureState = organizedData(from: receivedRawData).temperature
            self.humidityState = organizedData(from: receivedRawData).humidity
        }
        
        
        if temperatureRecords.isEmpty && humidityRecords.isEmpty {
            temperatureRecords.append(TemperatureRecord(value: temperatureState.value, timestamp: Date()))
            humidityRecords.append(HumidityRecord(value: humidityState.value, timestamp: Date()))
        }
        
    }
    
    // Core Data Support
    // 将内容持久化存储到本地数据库中
    private func addItem() {
        let newItem = DHTData(context: viewContext)
        newItem.timestamp = temperatureRecords.last!.timestamp
        newItem.temperature = Int64(temperatureState.value * 10)
        newItem.humidity = Int64(humidityState.value * 10)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    // Network Support
    //  服务端开始监听并处理连接
    private func serverConnectAction() {
        
        listener = try! NWListener(using: .tcp, on: NWEndpoint.Port(self.options.port)!)
        
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
    
    //  服务端接收来自 connection 的数据
    private func receive(on connection: NWConnection) {
        
        connection.receive(minimumIncompleteLength: .min, maximumLength: .max) { (content, context, isComplete, error) in
            if content != nil {
                switch options.isListeningHex {
                case true:
                    let data = content!.hexadecimal()
                    print("received: \(data)")
                    
                    withAnimation {
                        receivedRawData = data
                        updateDHTItems(using: .hex)
                    }
                    
                case false:
                    let data = String(data: content ?? "".data(using: .utf8)!, encoding: .utf8)
                    print("received: \(data!)")
                    if data!.isBinary() {
                        withAnimation {
                            receivedRawData = data!
                            updateDHTItems(using: .utf8)
                        }
                    }
                }
                
                if error == nil && isDataListeningEnabled {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + TimeInterval(1)) {
                        self.receive(on: connection)
                    }
                }
            }
        }
    }
    
    //  解析从客户端获取到的信息存入数据库、更新视图上下文
    private func updateDHTItems(using category: DataCategory) {
        
        switch category {
        case .hex:
            temperatureState.value = organizedData(fromHex: receivedRawData).temperature.value
            humidityState.value = organizedData(fromHex: receivedRawData).humidity.value
        case .utf8:
            temperatureState.value = organizedData(from: receivedRawData).temperature.value
            humidityState.value = organizedData(from: receivedRawData).humidity.value
        }
        
        updateChart()
        
        addItem()
    }
    
    private func updateChart() {
        var maxStorage = 64
#if os(iOS)
        if horizontalSizeClass == .compact {
            maxStorage = 32
        }
#endif
        //如果数据来自同一秒，修改最新的数据，否则添加一个新的数据
        if temperatureRecords.last?.timestamp.formatted(date: .omitted, time: .standard) == Date().formatted(date: .omitted, time: .standard) {
            temperatureRecords[temperatureRecords.count - 1].value = temperatureState.value
        } else {
            temperatureRecords.append(TemperatureRecord(value: temperatureState.value, timestamp: Date()))
        }
        
        if humidityRecords.last?.timestamp.formatted(date: .omitted, time: .standard) == Date().formatted(date: .omitted, time: .standard) {
            humidityRecords[humidityRecords.count - 1].value = humidityState.value
        } else {
            humidityRecords.append(HumidityRecord(value: humidityState.value, timestamp: Date()))
        }
        
        if temperatureRecords.count >= maxStorage {
            temperatureRecords.remove(at: 0)
        }
        if humidityRecords.count >= maxStorage {
            humidityRecords.remove(at: 0)
        }
    }
    
    
    // User Interface Support
    private func verticalSpacingForHorizontalSizeClass() -> CGFloat {
#if os(iOS)
        if horizontalSizeClass == .compact {
            return 8
        } else {
            return 16
        }
#else
        return 16
#endif
    }
    
    private func updatedTemperatureLevel() -> TemperatureLevel {
        switch temperatureState.value {
        case -20..<10:
            return .low
        case 10..<50:
            return .medium
        case 50..<80:
            return .high
        default:
            return .medium
        }
    }
    
    private func thermometerImage() -> Image {
        return Image(systemName: "thermometer.\(temperatureLevel.rawValue)")
    }
    
    private func temperatureChartBarMarkGradient(from record: TemperatureRecord) -> LinearGradient {
        return LinearGradient(colors: [.red, .yellow, .teal],
                              startPoint: UnitPoint(x: UnitPoint.top.x,
                                                    y: record.value >= 0 ?
                                                    UnitPoint.bottom.y + 80 * ((UnitPoint.top.y - UnitPoint.bottom.y) / CGFloat(record.value))
                                                    : UnitPoint.top.y + 80 * ((UnitPoint.top.y - UnitPoint.bottom.y) / CGFloat(-record.value))
                                                   ),
                              
                              endPoint: UnitPoint(x: UnitPoint.bottom.x,
                                                  y: record.value >= 0 ?
                                                  UnitPoint.bottom.y - 20 * ((UnitPoint.top.y - UnitPoint.bottom.y) / CGFloat(record.value))
                                                  : UnitPoint.top.y - 20 * ((UnitPoint.top.y - UnitPoint.bottom.y) / CGFloat(-record.value))
                                                 )
        )
    }
    
    private func humidityChartBarMarkGradient(from record: HumidityRecord) -> LinearGradient {
        return LinearGradient(colors: [.mint, .cyan, .indigo],
                              startPoint: .bottom,
                              endPoint: UnitPoint(x: UnitPoint.bottom.x,
                                                  y: UnitPoint.bottom.y + (UnitPoint.top.y - UnitPoint.bottom.y) / (record.value / 100)
                                                 ))
    }
    
}

struct DHTSensorMonitor_Previews: PreviewProvider {
    static var previews: some View {
        DHTSensorMonitor()
    }
}
