//
//  NavigationDetailView.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/24.
//

import SwiftUI

struct NavigationDetailView: View {
    @EnvironmentObject var store: NavigationStore
    
    var body: some View {
        if let selection = store.selection {
            switch selection {
            
            case 0:
                IlluminanceSensorView()
                    .onDisappear {
                        if listener.state != .cancelled {
                            listener.cancel()
                        }
                    }
            case 1:
                DHTSensorView()
                    .onDisappear {  
                        if listener.state != .cancelled {
                            listener.cancel()
                        }
                    }
                
            default:
                LaunchScreen()
            }
        } else {
            LaunchScreen()
        }
    }
}

struct NavigationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationDetailView()
    }
}
