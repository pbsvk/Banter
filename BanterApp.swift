//
//  BanterApp.swift
//  Banter
//
//  Created by Bhaskara Padala on 1/14/25.
//

import SwiftUI
import Appwrite

// Your imports remain the same

@main
struct BanterApp: App {
    // Use StateObjects for services
    @StateObject private var authService: AuthService
    @StateObject private var databaseService: DatabaseService
    
    init() {
        // Use the shared AppwriteService instance
        let appwriteService = AppwriteService.shared
        print("Initializing BanterApp with AppwriteService")
        
        // Initialize services with the shared client
        let auth = AuthService(client: appwriteService.client)
        let database = DatabaseService(client: appwriteService.client)
        
        // Initialize StateObjects
        _authService = StateObject(wrappedValue: auth)
        _databaseService = StateObject(wrappedValue: database)
        
        print("BanterApp initialization completed")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(databaseService)
        }
    }
}

// End of file
