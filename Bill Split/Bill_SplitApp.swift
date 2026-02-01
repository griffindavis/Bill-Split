//
//  Bill_SplitApp.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import SwiftUI

@main
struct Bill_SplitApp: App {
    
    @StateObject var model: Model = Model()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
