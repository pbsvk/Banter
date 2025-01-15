//
//  DatabaseService.swift
//  Banter
//
//  Created by Bhaskara Padala on 1/14/25.
//

import Foundation
import Appwrite
import SwiftUI

class DatabaseService: ObservableObject {
    // Database properties
    private let database: Databases
    private let databaseId: String
    private let conversationCollectionId: String
    private let messageCollectionId: String
    
    // Published properties for UI updates
    @Published var conversations: [Conversation] = []
    @Published var messages: [Message] = []
    
    init(client: Client,
         databaseId: String = "6786e3ee00313256cf72",
         conversationCollectionId: String = "6786e3f8002f9c84f40a",
         messageCollectionId: String = "6786e491002c02e6f3af") {
        self.database = Databases(client)
        self.databaseId = databaseId
        self.conversationCollectionId = conversationCollectionId
        self.messageCollectionId = messageCollectionId
    }
    
    // MARK: - Conversation Methods
    
    @MainActor
    func fetchConversations(for userId: String) async throws {
        print("Fetching conversations for user: \(userId)")
        let response = try await database.listDocuments(
            databaseId: databaseId,
            collectionId: conversationCollectionId,
            queries: [Query.equal("members", value: userId)]
        )
        
        print("Found \(response.documents.count) conversations")
        self.conversations = try response.documents.map { document in
            guard let members = document.data["members"]?.value as? [String] else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid members data"])
            }
            
            return Conversation(
                id: document.id,
                members: members,
                lastMessage: document.data["lastMessage"]?.value as? String,
                lastMessageTimestamp: ISO8601DateFormatter().date(from: document.data["lastMessageTimestamp"]?.value as? String ?? "")
            )
        }
    }
    
    @MainActor
    func fetchMessages(for conversationId: String) async throws {
        print("Fetching messages for conversation: \(conversationId)")
        let response = try await database.listDocuments(
            databaseId: databaseId,
            collectionId: messageCollectionId,
            queries: [
                Query.equal("conversationId", value: conversationId),
                Query.orderDesc("$createdAt")
            ]
        )
        
        print("Found \(response.documents.count) messages")
        self.messages = try response.documents.map { document in
            guard let conversationId = document.data["conversationId"]?.value as? String,
                  let senderId = document.data["senderId"]?.value as? String,
                  let text = document.data["text"]?.value as? String,
                  let createdAt = document.data["$createdAt"]?.value as? String,
                  let timestamp = ISO8601DateFormatter().date(from: createdAt) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid message data"])
            }
            
            return Message(
                id: document.id,
                conversationId: conversationId,
                senderId: senderId,
                text: text,
                timestamp: timestamp
            )
        }
    }
    
    // MARK: - Conversation Methods remain the same
    
    @MainActor
    func createConversation(members: [String]) async throws {
        print("Creating conversation with members: \(members)")
        
        let data: [String: Any] = [
            "members": members,
            "lastMessage": "",
            "lastMessageTimestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Create permissions array for each member
        var permissions: [String] = []
        for member in members {
            permissions.append("read(\"user:\(member)\")")
            permissions.append("write(\"user:\(member)\")")
        }
        
        let document = try await database.createDocument(
            databaseId: databaseId,
            collectionId: conversationCollectionId,
            documentId: ID.unique(),
            data: data,
            permissions: permissions
        )
        
        // Rest of the function remains the same
        print("Conversation created with ID: \(document.id)")
        let conversation = Conversation(
            id: document.id,
            members: members,
            lastMessage: nil,
            lastMessageTimestamp: ISO8601DateFormatter().date(from: document.data["$createdAt"]?.value as? String ?? "")
        )
        
        self.conversations.append(conversation)
        self.conversations.sort { ($0.lastMessageTimestamp ?? .distantPast) > ($1.lastMessageTimestamp ?? .distantPast) }
    }
    
    @MainActor
    func sendMessage(conversationId: String, senderId: String, text: String) async throws {
        print("Sending message in conversation: \(conversationId)")
        
        let messageData: [String: Any] = [
            "conversationId": conversationId,
            "senderId": senderId,
            "text": text
        ]
        
        // Get conversation members first
        let conversation = try await database.getDocument(
            databaseId: databaseId,
            collectionId: conversationCollectionId,
            documentId: conversationId
        )
        
        guard let members = conversation.data["members"]?.value as? [String] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get conversation members"])
        }
        
        // Create permissions array for each member
        var permissions: [String] = []
        for member in members {
            permissions.append("read(\"user:\(member)\")")
            permissions.append("write(\"user:\(member)\")")
        }
        
        // Create message with permissions for all members
        let document = try await database.createDocument(
            databaseId: databaseId,
            collectionId: messageCollectionId,
            documentId: ID.unique(),
            data: messageData,
            permissions: permissions
        )
        
    }
}// Rest of the function remains the same

// Model structs
struct Conversation: Identifiable {
    let id: String
    let members: [String]
    let lastMessage: String?
    let lastMessageTimestamp: Date?
}

struct Message: Identifiable, Hashable {
    let id: String
    let conversationId: String
    let senderId: String
    let text: String
    let timestamp: Date
}

// End of file
