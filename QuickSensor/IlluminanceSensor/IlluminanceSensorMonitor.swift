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
    
    @State private var illuminanceSensorState: IlluminanceSensorState = .init(isIlluminated: false)
    
    var body: some View {
        VStack {
            lightbulbSymbol
            Text(illuminanceSensorState.isIlluminated ? "Illuminated" : "Not Illuminated")
                .font(.system(.largeTitle, design: .rounded))
#if os(iOS)
                        .bold()
#endif
        }
        
        
        
        
    }
    
    var lightbulbSymbol: some View {
        Image(systemName: illuminanceSensorState.isIlluminated ? "lightbulb.fill" : "lightbulb")
            .foregroundColor(illuminanceSensorState.isIlluminated ? .yellow : .gray)
            .symbolRenderingMode(.multicolor)
            .font(.largeTitle)
            .imageScale(.large)
            .padding()
    }
}

struct IlluminanceSensorMonitor_Previews: PreviewProvider {
    static var previews: some View {
        IlluminanceSensorMonitor()
    }
}
