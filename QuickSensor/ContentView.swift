//
//  ContentView.swift
//  QuickSensor
//
//  Created by 徐嗣苗 on 2022/10/21.
//

import SwiftUI
class NavigationStore: ObservableObject {
    @Published var selection: Int?
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject var store = NavigationStore()
    
    var body: some View {
        NavigationSplitView {
            SidebarNavigationList()
#if os(macOS)
                .navigationSplitViewColumnWidth(min: 130, ideal: 180, max: 200)
#endif
        } detail: {
            NavigationDetailView()
        }
        .environmentObject(store)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
