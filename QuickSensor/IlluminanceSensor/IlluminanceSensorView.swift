//
//  IlluminanceSensorView.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/30.
//

import SwiftUI

struct IlluminanceSensorView: View {
    var body: some View {
        NavigationStack {
            IlluminanceSensorMonitor()
        }
    }
}

struct IlluminanceSensorView_Previews: PreviewProvider {
    static var previews: some View {
        IlluminanceSensorView()
    }
}
