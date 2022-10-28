//
//  SettingsView.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/28.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            Text("General")
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            Text("Appearance")
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }
            
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
