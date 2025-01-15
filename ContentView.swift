//
//  ContentView.swift
//  Banter
//
//  Created by Bhaskara Padala on 1/14/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                ConversationListView()
                    .transition(.opacity) // Add smooth transition
            } else {
                AuthView()
                    .transition(.opacity) // Add smooth transition
            }
        }
        .animation(.default, value: authService.isAuthenticated) // Animate the transition
    }
}

// End of file

#Preview {
    ContentView()
        .environmentObject(AuthService(client: AppwriteService.shared.client))
        .environmentObject(DatabaseService(client: AppwriteService.shared.client))
}
