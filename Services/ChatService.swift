//
//  ChatService.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//
import Foundation
import Supabase
import CryptoKit

class ChatService {
    private let supabase = SupabaseConfig.shared.client
    
    // البحث عن مستخدم متاح
    func findAvailableUser(excludingUserId: String) async throws -> User? {
        let response = try await supabase
            .from("users")
            .select()
            .eq("is_available", value: true)
            .neq("auth_user_id", value: excludingUserId)
            .limit(10)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let users = try decoder.decode([User].self, from: response.data)
        return users.filter { $0.authUserId != excludingUserId }.randomElement()
    }
    
    // إنشاء محادثة مشفرة
    func createEncryptedChat(user1AuthId: String, user2UserId: String) async throws -> (chatId: String, symmetricKey: SymmetricKey) {
        
        // توليد أزواج المفاتيح
        let (privateKey1, publicKey1) = EncryptionService.generateKeyPair()
        let (_, publicKey2) = EncryptionService.generateKeyPair()
        
        // الحصول على user1Id من auth_user_id
        let user1Response = try await supabase
            .from("users")
            .select()
            .eq("auth_user_id", value: user1AuthId)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let user1 = try decoder.decode(User.self, from: user1Response.data)
        
        // إنشاء المحادثة
        struct ChatInsert: Encodable {
            let user1_id: String
            let user2_id: String
            let user1_public_key: String
            let user2_public_key: String
            let is_active: Bool
        }
        
        let chatData = ChatInsert(
            user1_id: user1.id,
            user2_id: user2UserId,
            user1_public_key: EncryptionService.publicKeyToString(publicKey1),
            user2_public_key: EncryptionService.publicKeyToString(publicKey2),
            is_active: true
        )
        
        let chatResponse = try await supabase
            .from("chats")
            .insert(chatData)
            .select()
            .single()
            .execute()
        
        let chat = try decoder.decode(Chat.self, from: chatResponse.data)
        
        // اشتقاق المفتاح المشترك
        let symmetricKey = try EncryptionService.deriveSymmetricKey(
            privateKey: privateKey1,
            publicKey: publicKey2
        )
        
        // حفظ المفتاح الخاص
        try KeychainService.savePrivateKey(
            EncryptionService.privateKeyToString(privateKey1),
            for: chat.id
        )
        
        // تحديث المستخدمين
        struct UserUpdate: Encodable {
            let current_chat_id: String
            let is_available: Bool
        }
        
        let update = UserUpdate(current_chat_id: chat.id, is_available: false)
        
        try await supabase
            .from("users")
            .update(update)
            .eq("id", value: user1.id)
            .execute()
        
        try await supabase
            .from("users")
            .update(update)
            .eq("id", value: user2UserId)
            .execute()
        
        return (chat.id, symmetricKey)
    }
    
    // إرسال رسالة مشفرة
    func sendEncryptedMessage(chatId: String, senderId: String, content: String, type: MessageType, symmetricKey: SymmetricKey) async throws {
        
        let encryptedContent = try EncryptionService.encryptText(content, using: symmetricKey)
        
        struct MessageInsert: Encodable {
            let chat_id: String
            let sender_id: String
            let type: String
            let content: String
            let is_read: Bool
        }
        
        let messageData = MessageInsert(
            chat_id: chatId,
            sender_id: senderId,
            type: type.rawValue,
            content: encryptedContent,
            is_read: false
        )
        
        try await supabase
            .from("messages")
            .insert(messageData)
            .execute()
        
        // تحديث وقت آخر رسالة
        struct ChatUpdate: Encodable {
            let last_message_at: String
        }
        
        let update = ChatUpdate(last_message_at: ISO8601DateFormatter().string(from: Date()))
        
        try await supabase
            .from("chats")
            .update(update)
            .eq("id", value: chatId)
            .execute()
    }
    
    // استرجاع المفتاح المشترك
    func getSymmetricKey(for chatId: String, userId: String) async throws -> SymmetricKey {
        let chatResponse = try await supabase
            .from("chats")
            .select()
            .eq("id", value: chatId)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let chat = try decoder.decode(Chat.self, from: chatResponse.data)
        
        let isUser1 = chat.user1Id == userId
        
        let privateKeyString = try KeychainService.getPrivateKey(for: chatId)
        let privateKey = try EncryptionService.stringToPrivateKey(privateKeyString)
        
        let otherPublicKeyString = isUser1 ? chat.user2PublicKey : chat.user1PublicKey
        let otherPublicKey = try EncryptionService.stringToPublicKey(otherPublicKeyString)
        
        return try EncryptionService.deriveSymmetricKey(
            privateKey: privateKey,
            publicKey: otherPublicKey
        )
    }
    
    // إنهاء المحادثة
    func endChat(chatId: String, userId: String) async throws {
        struct ChatUpdate: Encodable {
            let is_active: Bool
        }
        
        try await supabase
            .from("chats")
            .update(ChatUpdate(is_active: false))
            .eq("id", value: chatId)
            .execute()
        
        struct UserUpdate: Encodable {
            let current_chat_id: String?
            let is_available: Bool
        }
        
        try await supabase
            .from("users")
            .update(UserUpdate(current_chat_id: nil, is_available: true))
            .eq("id", value: userId)
            .execute()
        
        KeychainService.deletePrivateKey(for: chatId)
    }
}
