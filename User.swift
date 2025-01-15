//
//  User.swift
//  Banter
//
//  Created by Bhaskara Padala on 1/14/25.
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let email: String
    
    init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
    
    // Create from Appwrite document dictionary
    static func from(document: [String: Any]) throws -> User {
        guard let id = document["$id"] as? String,
              let name = document["name"] as? String,
              let email = document["email"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user data"])
        }
        
        return User(id: id, name: name, email: email)
    }
    
    // Convert to dictionary for Appwrite
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "email": email
        ]
    }
}

// End of file
