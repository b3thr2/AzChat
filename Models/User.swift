//
//  User.swift
//  
//
//  Created by Amal  on 19/08/1447 AH.
//
import Foundation

struct User: Codable, Identifiable {
    let id: String
    let createdAt: Date
    var isAvailable: Bool
    var currentChatId: String?
    let authUserId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case isAvailable = "is_available"
        case currentChatId = "current_chat_id"
        case authUserId = "auth_user_id"
    }
}
