//
//  HelloTApp.swift
//  HelloT
//
//  Created by Jingyu Du on 2026/6/7.
//

import SwiftUI
import FirebaseCore

@main
struct HelloTApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
            } else {
                LoginView()
            }
        }
    }
}
