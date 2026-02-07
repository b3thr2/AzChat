//
//  MatchingViewModel.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//
import Foundation

@MainActor
class MatchingViewModel: ObservableObject {
    @Published var isSearching = false
    @Published var matchedChatId: String?
    @Published var errorMessage: String?
    
    private let firestoreService = FirestoreService()
    
    var currentUserId: String
    
    init(currentUserId: String) {
        self.currentUserId = currentUserId
    }
    
    func findMatch() async {
        isSearching = true
        errorMessage = nil
        
        do {
            // تحديث حالة التوفر
            try await firestoreService.updateUserAvailability(userId: currentUserId, isAvailable: true)
            
            // محاولة إيجاد مستخدم متاح
            var attempts = 0
            while attempts < 10 && matchedChatId == nil {
                if let matchedUser = try await firestoreService.findAvailableUser(excludingUserId: currentUserId) {
                    // إنشاء محادثة
                    let chatId = try await firestoreService.createChat(
                        user1Id: currentUserId,
                        user2Id: matchedUser.id
                    )
                    matchedChatId = chatId
                    break
                }
                
                // انتظر ثانية قبل المحاولة التالية
                try await Task.sleep(nanoseconds: 1_000_000_000)
                attempts += 1
            }
            
            if matchedChatId == nil {
                errorMessage = "لم يتم العثور على شخص متاح. حاول مرة أخرى."
                try await firestoreService.updateUserAvailability(userId: currentUserId, isAvailable: false)
            }
            
        } catch {
            errorMessage = "حدث خطأ: \(error.localizedDescription)"
        }
        
        isSearching = false
    }
    
    func cancelSearch() async {
        do {
            try await firestoreService.updateUserAvailability(userId: currentUserId, isAvailable: false)
        } catch {
            print("Error canceling search: \(error)")
        }
        isSearching = false
    }
}
