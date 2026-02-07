//
//  Message.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//

import Foundation

enum MessageType: String, Codable {
    case text
    case image
}

struct Message: Codable, Identifiable {
    let id: String
    let chatId: String
    let senderId: String
    let type: MessageType
    let content: String // محتوى مشفر
    let timestamp: Date
    var isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case chatId = "chat_id"
        case senderId = "sender_id"
        case type
        case content
        case timestamp
        case isRead = "is_read"
    }
}

