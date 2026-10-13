//
//  OnsarjApp.swift
//  Onsarj
//
//  Created by Mehmet Akan on 1.10.2026.
//

import SwiftUI

@main
struct OnsarjApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
