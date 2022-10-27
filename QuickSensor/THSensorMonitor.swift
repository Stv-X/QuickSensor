//
//  THSensorMonitor.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/21.
//

import SwiftUI
import Charts

struct THSensorMonitor: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    #endif
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \THData.timestamp, ascending: true)],
        animation: .default)
    
    private var items: FetchedResults<THData>
    
    @State private var receivedRawData = "0000001010010010000000010000110110100010"
    
    @State private var temperatureState = TemperatureState(value: 30)
    @State private var temperatureLevel = TemperatureLevel.medium
    @State private var temperatureRecords: [TemperatureRecord] = []
    
    @State private var humidityState = HumidityState(value: 23)
    @State private var humidityRecords: [HumidityRecord] = []
    
    @State private var isOptionsPopoverPresented = false
    @State private var options = THSensorMonitorOptions()
    
    @State private var isAutoRefreshEnabled = false
    
    private let autoRefreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    
    var body: some View {
        VStack {
            Grid(horizontalSpacing: 20, verticalSpacing: 16) {
                GridRow {
                    ThermometerSymbol(level: $temperatureLevel)
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
                                        AxisValueLabel("""
                                        \(value.as(PlottableTemperatureMeasurement.self)!.measurement.converted(to: .celsius),
                                        format: .measurement(
                                            width: .narrow,
                                            numberFormatStyle: .number.precision(
                                                .fractionLength(0))
                                            )
                                        )
                                        """)
                        }
                    }
                    .chartYScale(domain: -20...80)
#if os(iOS)
                    .chartYAxis(horizontalSizeClass == .compact ? .hidden : .visible)
#endif
                    .padding(.trailing)
                    .frame(height: 80)
                }
                .padding(.vertical)
                
                Divider()
                GridRow {
                    HumiditySymbol()
                    
                    Text("\(NSNumber(value: Double(String(format:"%.1f", humidityState.value))!))%")
                        .font(.system(.largeTitle, design: .rounded))
                        .padding(.trailing)
#if os(iOS)
                        .bold()
                        .frame(width: 140)
#endif
                    
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
                        AxisMarks(values: .stride(by: 20)) { value in
                            AxisGridLine()
                            AxisValueLabel(LocalizedStringKey(stringLiteral: "\(value.index * 20)%"))
                        }
                    }
                    .chartYScale(domain: 0...100)
#if os(iOS)
                    .chartYAxis(horizontalSizeClass == .compact ? .hidden : .visible)
#endif
                    .padding(.trailing)
                    .frame(height: 80)
                }
                .padding(.vertical)
                
            }
            
            Divider()
            
            DisclosureGroup("Details") {
                DetailsGroup
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
                SensorDataRefreshButton
                OptionsButton
            }
            
        }
        #if os(iOS)
        .toolbarRole(.browser)
        #endif
        
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
    
    //MARK: Toolbar Buttons
    
    // 􀊃 Auto Refresh
    private var SensorDataAutoRefreshButton: some View {
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
                sensorRefreshAction()
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
        #if os(macOS)
        .popover(isPresented: $isOptionsPopoverPresented) {
            THSensorMonitorOptionsPopover(isPresented: $isOptionsPopoverPresented,
                                        options: $options)
        }
        #else
        .sheet(isPresented: $isOptionsPopoverPresented) {
            NavigationStack {
                THSensorMonitorOptionsPopover(isPresented: $isOptionsPopoverPresented,
                                              options: $options)
            }
        }
        #endif
        .disabled(isAutoRefreshEnabled)
    }
    
    //MARK: Details Group
    
    private var DetailsGroup: some View {
        HStack {
            VStack(alignment: .leading) {
                GroupBox {
                    Text(receivedRawData.readableBinary())
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
                
                HStack {
                    GroupBox {
                        Text("\(formattedRawData(from: receivedRawData).humidityHigh.readableBinary()) \(formattedRawData(from: receivedRawData).humidityLow.readableBinary())")
                            .font(.system(.body, design: .monospaced))
#if os(macOS)
                            .frame(width: 164)
#endif
                            .contextMenu {
                                Button {
                                    copyToClipBoard(textToCopy: formattedRawData(from: receivedRawData).humidityHigh + formattedRawData(from: receivedRawData).humidityLow)
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                            }
                        
                    } label: {
                        Text("Humidity Raw Data")
                    }
                    
                    GroupBox {
                        Text("\(formattedRawData(from: receivedRawData).temperatureHigh.readableBinary()) \(formattedRawData(from: receivedRawData).temperatureLow.readableBinary())")
                            .font(.system(.body, design: .monospaced))
#if os(macOS)
                            .frame(width: 164)
#endif
                            .contextMenu {
                                Button {
                                    copyToClipBoard(textToCopy: formattedRawData(from: receivedRawData).temperatureHigh + formattedRawData(from: receivedRawData).temperatureLow)
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                            }
                        
                    } label: {
                        Text("Temperature Raw Data")
                    }
                }
                
                GroupBox {
                    Text(formattedRawData(from: receivedRawData).verifyBit.readableBinary())
                        .font(.system(.body, design: .monospaced))
#if os(macOS)
                        .frame(width: 74)
#endif
                        .contextMenu {
                            Button {
                                copyToClipBoard(textToCopy: formattedRawData(from: receivedRawData).verifyBit)
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                    
                } label: {
                    Text("Verify Bit")
                }
                
                Spacer()
            }
            Spacer()
            
        }
    }
    
    //MARK: Private Functions
    
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
//            addItem()
        }
        
        
    }
    
    private func addItem() {
        let newItem = THData(context: viewContext)
        newItem.timestamp = Date()
        newItem.temperature = Int64(temperatureState.value * 10)
        newItem.humidity = Int64(humidityState.value * 10)
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func sensorRefreshAction() {
        
        var maxStorage = 64
        
        #if os(iOS)
        if horizontalSizeClass == .compact {
            maxStorage = 32
        }
        #endif
        
        receivedRawData = randomTHSensorRawData()
        temperatureState.value = organizedData(from: receivedRawData).temperature.value
        humidityState.value = organizedData(from: receivedRawData).humidity.value
        
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
        
        addItem()
        
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
    
    private func formattedRawData(from rawData: String) -> THRawData {
        let splitedRawData = rawData.split(separator: "")
        var formattedRawData: [Int] = []
        for i in splitedRawData {
            formattedRawData.append(Int(i)!)
        }
        var rawData = THRawData(humidityHigh: "", humidityLow: "", temperatureHigh: "", temperatureLow: "", verifyBit: "")
        
        rawData.map(from: formattedRawData)
        return rawData
    }
    
    private func organizedData(from rawData: String) -> OrganizedData {
        var organizedData = OrganizedData(temperature: TemperatureState(value: 30.0),
                                          humidity: HumidityState(value: 23.0),
                                          isVerified: false)
        
        let formattedRawData = formattedRawData(from: rawData)
        
//        print(formattedRawData)
        
        var humidityRaw = ""
        var temperatureRaw = ""
        
        humidityRaw = formattedRawData.humidityHigh + formattedRawData.humidityLow
        temperatureRaw = formattedRawData.temperatureHigh + formattedRawData.temperatureLow
        
        organizedData.isVerified = verifiedTHData(from: formattedRawData)
        organizedData.humidity.value = Double(humidityRaw.toDec()) / 10
        organizedData.temperature.value = Double(temperatureRaw.toTDec()) / 10
        
        return organizedData
    }
    
    private func verifiedTHData(from rawData: THRawData) -> Bool {
        var data = rawData
        let a = data.humidityHigh.toDec() + data.humidityLow.toDec() + data.temperatureHigh.toDec() + data.temperatureLow.toDec()
        
        let b = data.verifyBit.toDec()
        
        if a == b {
            return true
        } else {
            return false
        }
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

//MARK: Dynamic Symbols
// 􀇬 Temperature
struct ThermometerSymbol: View {
    @Binding var level: TemperatureLevel
    var body: some View {
        thermometerImage
            .imageScale(.large)
            .font(.largeTitle)
            .foregroundColor(.red)
            .symbolRenderingMode(.hierarchical)
            .padding()
    }
    
    private var thermometerImage: some View {
        return Image(systemName: "thermometer.\(level.rawValue)")
    }
}

// 􁃚 Humidity
struct HumiditySymbol: View {
    var body: some View {
        Image(systemName: "humidity")
            .imageScale(.large)
            .font(.largeTitle)
            .foregroundColor(.blue)
            .symbolRenderingMode(.hierarchical)
            .padding()
    }
}

//MARK: Options Popover

struct THSensorMonitorOptionsPopover: View {
    @Binding var isPresented: Bool
    @Binding var options: THSensorMonitorOptions
    
    @State private var onEditingOptions = THSensorMonitorOptions()
    
    var body: some View {
        VStack {
            Form {
                // Serial Port Picker
                Picker("COM Port", selection: $onEditingOptions.serialPort) {
                    ForEach(0..<8) { i in
                        Text("COM \(i)")
                            .tag(i)
                    }
                }
                
                // Baud Rate Stepper
                Stepper {
                    HStack {
                        Text("Baud Rate")
                        Spacer()
                        Text("\(onEditingOptions.baudRate)")
                    }
                } onIncrement: {
                    baudRateIncrementStep()
                } onDecrement: {
                    baudRateDecrementStep()
                }
                
//                Text("Option 3")
            }
            .formStyle(.grouped)
#if os(macOS)
            .frame(width: 260)
#endif
            
#if os(macOS)
            Divider()

            // Buttons
            HStack {
                Spacer()
                
                Button("Confirm") {
                    options = onEditingOptions
                    isPresented.toggle()
                }
                .keyboardShortcut(.defaultAction)
                
                Button("Cancel") {
                    isPresented.toggle()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
#endif
        }
        
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Confirm") {
                    options = onEditingOptions
                    isPresented.toggle()
                }
                .keyboardShortcut(.defaultAction)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented.toggle()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
#endif
        
        .onAppear {
            onEditingOptions = options
        }
    }
    
    private func baudRateIncrementStep() {
        if onEditingOptions.baudRate == availableBaudRates.first! {} else {
            onEditingOptions.baudRate = availableBaudRates[availableBaudRates.firstIndex(of: onEditingOptions.baudRate)! - 1]
        }
    }
    
    private func baudRateDecrementStep() {
        if onEditingOptions.baudRate == availableBaudRates.last! {} else {
            onEditingOptions.baudRate = availableBaudRates[availableBaudRates.firstIndex(of: onEditingOptions.baudRate)! + 1]
        }
    }
}

struct THSensorMonitor_Previews: PreviewProvider {
    static var previews: some View {
//        THSensorMonitorOptionsPopover(isPresented: .constant(true), options: .constant(THSensorMonitorOptions()))
        THSensorMonitor()
    }
}
