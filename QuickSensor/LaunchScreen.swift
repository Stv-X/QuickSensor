//
//  LaunchScreen.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/24.
//

import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        VStack {
            Image(systemName: "sensor.fill")
                .font(.system(size: 120))
                .padding()
                .offset(x: 10)
            
            Text("QuickSensor")
                .font(.largeTitle)
                .bold()
        }
        .opacity(0.5)
        .padding()
    }
}

struct LaunchScreen_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreen()
    }
}
