//
//  Chat.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//

import Foundation

struct Chat: Codable, Identifiable {
    let id: String
    let user1Id: String
    let user2Id: String
    let user1PublicKey: String
    let user2PublicKey: String
    let createdAt: Date
    var isActive: Bool
    var lastMessageAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case user1PublicKey = "user1_public_key"
        case user2PublicKey = "user2_public_key"
        case createdAt = "created_at"
        case isActive = "is_active"
        case lastMessageAt = "last_message_at"
    }
}
