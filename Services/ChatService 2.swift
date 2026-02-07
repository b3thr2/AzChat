//
//  ChatService 2.swift
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
        
        struct UsersResponse: Decodable {
            let data: [User]
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let users = try decoder.decode([User].self, from: response.data)
        return users.filter { $0.authUserId != excludingUserId }.randomElement()
    }
    
    // إنشاء محادثة مشفرة
    func createEncryptedChat(user1AuthId: String, user2UserId: String) async throws -> (chatId: String, symmetricKey: SymmetricKey) {
        
        // توليد أزواج المفاتيح
        let (privateKey1, publicKey1) = EncryptionService.generateKeyPair()
        let (privateKey2, publicKey2) = EncryptionService.generateKeyPair()
        
        // الحصول على user1Id من auth_user_id
        let user1Response = try await supabase
            .from("users")
            .select()
            .eq("auth_user_id", value: user1AuthId)
            .single()
            .execute()
        
        let user1 = try JSONDecoder().decode(User.self, from: user1Response.data)
        
        // إنشاء المحادثة
        let chatData: [String: Any] = [
            "user1_id": user1.id,
            "user2_id": user2UserId,
            "user1_public_key": EncryptionService.publicKeyToString(publicKey1),
            "user2_public_key": EncryptionService.publicKeyToString(publicKey2),
            "is_active": true
        ]
        
        let chatResponse = try await supabase
            .from("chats")
            .insert(chatData)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
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
        try await supabase
            .from("users")
            .update(["current_chat_id": chat.id, "is_available": false])
            .eq("id", value: user1.id)
            .execute()
        
        try await supabase
            .from("users")
            .update(["current_chat_id": chat.id, "is_available": false])
            .eq("id", value: user2UserId)
            .execute()
        
        return (chat.id, symmetricKey)
    }
    
    // إرسال رسالة مشفرة
    func sendEncryptedMessage(chatId: String, senderId: String, content: String, type: MessageType, symmetricKey: SymmetricKey) async throws {
        
        let encryptedContent = try EncryptionService.encryptText(content, using: symmetricKey)
        
        let messageData: [String: Any] = [
            "chat_id": chatId,
            "sender_id": senderId,
            "type": type.rawValue,
            "content": encryptedContent,
            "is_read": false
        ]
        
        try await supabase
            .from("messages")
            .insert(messageData)
            .execute()
        
        // تحديث وقت آخر رسالة
        try await supabase
            .from("chats")
            .update(["last_message_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: chatId)
            .execute()
    }
    
    // استرجاع المفتاح المشترك
    func getSymmetricKey(for chatId: String, userId: String) async throws -> SymmetricKey {
        // الحصول على بيانات المحادثة
        let chatResponse = try await supabase
            .from("chats")
            .select()
            .eq("id", value: chatId)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let chat = try decoder.decode(Chat.self, from: chatResponse.data)
        
        // تحديد أي المستخدمين
        let isUser1 = chat.user1Id == userId
        
        // استرجاع المفتاح الخاص
        let privateKeyString = try KeychainService.getPrivateKey(for: chatId)
        let privateKey = try EncryptionService.stringToPrivateKey(privateKeyString)
        
        // الحصول على المفتاح العام للطرف الآخر
        let otherPublicKeyString = isUser1 ? chat.user2PublicKey : chat.user1PublicKey
        let otherPublicKey = try EncryptionService.stringToPublicKey(otherPublicKeyString)
        
        // اشتقاق المفتاح المشترك
        return try EncryptionService.deriveSymmetricKey(
            privateKey: privateKey,
            publicKey: otherPublicKey
        )
    }
    
    // إنهاء المحادثة
    func endChat(chatId: String, userId: String) async throws {
        try await supabase
            .from("chats")
            .update(["is_active": false])
            .eq("id", value: chatId)
            .execute()
        
        try await supabase
            .from("users")
            .update(["current_chat_id": NSNull(), "is_available": true])
            .eq("id", value: userId)
            .execute()
        
        KeychainService.deletePrivateKey(for: chatId)
    }
}