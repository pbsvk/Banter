//
//  AppwriteService.swift
//  Banter
//
//  Created by Bhaskara Padala on 1/14/25.
//

import Foundation
import Appwrite

class AppwriteService {
    // Singleton instance
    static let shared = AppwriteService()
    
    // Appwrite client
    let client: Client
    
    // Your Appwrite project configuration
    private let endpoint = "https://cloud.appwrite.io/v1" // e.g., "https://cloud.appwrite.io/v1"
    private let projectId = "USEYOURID"
    
    private init() {
        // Initialize the Appwrite client
        client = Client()
            .setEndpoint(endpoint)
            .setProject(projectId)
            .setSelfSigned(true) // Only during development
    }
}

// End of file. No additional code.
