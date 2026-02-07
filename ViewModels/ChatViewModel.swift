//
//  ChatViewModel.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//
import Foundation
import Combine
import Supabase

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isTyping = false
    @Published var isSending = false
    @Published var errorMessage: String?
    
    private let firestoreService = FirestoreService()
    private let storageService = StorageService()
    private var messageListener: ListenerRegistration?
    
    var chatId: String
    var currentUserId: String
    
    init(chatId: String, currentUserId: String) {
        self.chatId = chatId
        self.currentUserId = currentUserId
        startListening()
    }
    
    func startListening() {
        messageListener = firestoreService.listenToMessages(chatId: chatId) { [weak self] messages in
            self?.messages = messages
        }
    }
    
    func sendTextMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSending = true
        
        do {
            try await firestoreService.sendMessage(
                chatId: chatId,
                senderId: currentUserId,
                content: text
            )
        } catch {
            errorMessage = "فشل إرسال الرسالة: \(error.localizedDescription)"
        }
        
        isSending = false
    }
    
    func sendImage(_ image: UIImage) async {
        isSending = true
        
        do {
            let imageUrl = try await storageService.uploadImage(image, chatId: chatId)
            
            let messageId = UUID().uuidString
            let message = Message(
                id: messageId,
                chatId: chatId,
                senderId: currentUserId,
                type: .image,
                content: imageUrl,
                timestamp: Date(),
                isRead: false
            )
            
            try await `SupabaseConfig.firestore()
                .collection("chats").document(chatId)
                .collection("messages").document(messageId)
                .setData(from: message)
            
        } catch {
            errorMessage = "فشل إرسال الصورة: \(error.localizedDescription)"
        }
        
        isSending = false
    }
    
    func endChat() async {
        do {
            try await firestoreService.endChat(chatId: chatId, userId: currentUserId)
        } catch {
            errorMessage = "فشل إنهاء المحادثة: \(error.localizedDescription)"
        }
    }
    
    deinit {
        messageListener?.remove()
    }
}
