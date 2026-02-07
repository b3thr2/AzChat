//
//  AuthService.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//
import Foundation
import Supabase
import Combine

@MainActor
class AuthService: ObservableObject {
    @Published var currentUserId: String?
    @Published var isAuthenticated = false
    
    private let supabase = SupabaseConfig.shared.client
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        Task {
            do {
                let session = try await supabase.auth.session
                self.currentUserId = session.user.id.uuidString
                self.isAuthenticated = true
            } catch {
                print("لا توجد جلسة نشطة")
            }
        }
    }
    
    func signInAnonymously() async throws {
        let session = try await supabase.auth.signInAnonymously()
        
        self.currentUserId = session.user.id.uuidString
        self.isAuthenticated = true
        
        // إنشاء سجل المستخدم في قاعدة البيانات
        try await createUserRecord(authUserId: session.user.id.uuidString)
    }
    
    private func createUserRecord(authUserId: String) async throws {
        struct UserInsert: Encodable {
            let auth_user_id: String
            let is_available: Bool
        }
        
        let userData = UserInsert(
            auth_user_id: authUserId,
            is_available: true
        )
        
        try await supabase
            .from("users")
            .insert(userData)
            .execute()
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        self.currentUserId = nil
        self.isAuthenticated = false
    }
}
