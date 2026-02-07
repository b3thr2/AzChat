//
//  TestView.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//

import SwiftUI
import Supabase

struct TestSupabaseView: View {
    @State private var message = "اضغط للاختبار"
    
    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .padding()
            
            Button("اختبر الاتصال بـ Supabase") {
                testConnection()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    func testConnection() {
        Task {
            do {
                // محاولة تسجيل دخول مجهول
                let session = try await SupabaseConfig.shared.client.auth.signInAnonymously()
                
                await MainActor.run {
                    message = "✅ الاتصال نجح!\nUser ID: \(session.user.id)"
                }
            } catch {
                await MainActor.run {
                    message = "❌ فشل الاتصال:\n\(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    TestSupabaseView()
}
