//
//  screentime_lboardApp.swift
//  screentime_lboard
//
//  Created by Sharan Subramanian on 9/4/25.
//

import SwiftUI

@main
struct screentime_lboardApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                        .environmentObject(authManager)
                } else {
                    AuthView()
                        .environmentObject(authManager)
                }
            }
            .onAppear {
                print("App started. Auth URL: https://dhwgtpetoqvlwfixrfjz.supabase.co")
            }
        }
    }
}
