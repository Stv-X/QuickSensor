//
//  IlluminanceSensorMonitor.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/27.
//

import SwiftUI

struct IlluminanceSensorState: Equatable {
    var isIlluminated: Bool
}

struct IlluminanceSensorMonitor: View {
    
    @State private var illuminanceSensorState = IlluminanceSensorState(isIlluminated: false)
    @State private var isAutoRefreshEnabled = false
    @State private var isOptionsPopoverPresented = false
    
    private let autoRefreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            lightbulbSymbol
            Text(illuminanceSensorState.isIlluminated ? "Illuminated" : "Not Illuminated")
                .font(.system(.largeTitle, design: .rounded))
#if os(iOS)
                        .bold()
                        .frame(width: 140)
#endif
            Divider()
            
            DisclosureGroup("Details") {
                DetailsGroup
                .padding(.vertical)
            }
            .padding(.horizontal)
            Spacer()
            
        }
        .frame(minWidth: 390, minHeight: 300)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                SensorDataAutoRefreshButton
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                SensorDataRefreshButton
                OptionsButton
            }
        }
        .onReceive(autoRefreshTimer) { _ in
            if isAutoRefreshEnabled {
                withAnimation {
//                    sensorRefreshAction()
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
    
}

struct IlluminanceSensorMonitor_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            IlluminanceSensorMonitor()
        }
    }
}
