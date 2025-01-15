//
//  AuthService.swift
//  Banter
//
//  Created by Bhaskara Padala on 1/14/25.
//

import Foundation
import Appwrite
import SwiftUI

class AuthService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false

    private let account: Account
    
    init(client: Client) {
        print("Initializing AuthService")
        account = Account(client)
        Task {
            await checkSession()
        }
    }

    // Check if user is already logged in
    @MainActor
    private func checkSession() async {
        do {
            print("Checking for existing session")
            let session = try await account.getSession(sessionId: "current")
            if session.id.isEmpty == false {
                await fetchCurrentUser()
                print("Active session found")
            }
        } catch {
            isAuthenticated = false
            print("No active session: \(error)")
        }
    }

    // Registration function
    // Modified registration function with all optionals properly handled
    @MainActor
    func register(name: String, email: String, password: String) async throws {
        do {
            print("Starting registration process for email: \(email)")
            
            // Create the user account
            let appwriteUser = try await account.create(
                userId: ID.unique(),
                email: email,
                password: password,
                name: name
            )
            
            print("User account created successfully")
            
            // Create session for the new user using email and password
            let session = try await account.createEmailPasswordSession(
                email: email,
                password: password
            )
            
            print("Session created for new user with ID: \(session.id)")
            user = User(id: appwriteUser.id, name: appwriteUser.name, email: appwriteUser.email)
            isAuthenticated = true
        } catch let error as AppwriteError {
            print("Appwrite error during registration: \(error.message ?? "")")
            print("Error type: \(error.type ?? "")")
            print("Error code: \(error.code ?? 0)")
            throw error
        } catch {
            print("Unexpected error during registration: \(error)")
            throw error
        }
    }

    // Login function
    // Modified login function to ensure proper state updates
    @MainActor
    func login(email: String, password: String) async throws {
        do {
            print("Starting login process for email: \(email)")
            
            // Create session using email and password
            let session = try await account.createEmailPasswordSession(
                email: email,
                password: password
            )
            
            print("Session created successfully: \(session.id)")
            await fetchCurrentUser()
            
            // Extra verification that authentication was successful
            if user == nil {
                isAuthenticated = false
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user after login"])
            }
            
            print("Login completed successfully, isAuthenticated: \(isAuthenticated)")
        } catch let error as AppwriteError {
            print("Appwrite error during login: \(error.message ?? "")")
            print("Error type: \(error.type ?? "")")
            print("Error code: \(error.code ?? 0)")
            isAuthenticated = false
            throw error
        } catch {
            print("Unexpected error during login: \(error)")
            isAuthenticated = false
            throw error
        }
    }

    // Logout function remains the same
    @MainActor
    func logout() async throws {
        print("Attempting to logout")
        _ = try await account.deleteSession(sessionId: "current")
        user = nil
        isAuthenticated = false
        print("Logout successful")
    }

    // Fetch current user function remains the same
    // Modified fetchCurrentUser to properly set authentication state
    @MainActor
    func fetchCurrentUser() async {
        do {
            print("Fetching current user information")
            let appwriteUser = try await account.get()
            user = User(id: appwriteUser.id, name: appwriteUser.name, email: appwriteUser.email)
            isAuthenticated = true
            print("User information fetched successfully. User: \(user?.email ?? "nil")")
        } catch {
            print("Failed to fetch current user: \(error.localizedDescription)")
            user = nil
            isAuthenticated = false
        }
    }
}

// End of file. No additional code.
