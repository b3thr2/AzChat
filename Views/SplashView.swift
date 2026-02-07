//
//  SplashView.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//
import SwiftUI

struct SplashView: View {
    @ObservedObject var authService: AuthService
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // الشعار
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)
            
            Text("محادثات عشوائية")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("تحدث مع أشخاص جدد بشكل مجهول")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
            
            Button {
                startAnonymousChat()
            } label: {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("ابدأ المحادثة")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(15)
            .padding(.horizontal, 40)
            .disabled(isLoading)
            
            Spacer()
                .frame(height: 50)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    func startAnonymousChat() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signInAnonymously()
                
                if let userId = authService.currentUserId {
                    try await FirestoreService().createUser(userId: userId)
                }
            } catch {
                errorMessage = "فشل الاتصال: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
