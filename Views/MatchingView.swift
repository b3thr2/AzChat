//
//  MatchingView.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//
import SwiftUI

struct MatchingView: View {
    let userId: String
    @StateObject private var viewModel: MatchingViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: MatchingViewModel(currentUserId: userId))
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if viewModel.isSearching {
                ProgressView()
                    .scaleEffect(2)
                
                Text("جاري البحث عن شخص...")
                    .font(.title3)
                    .padding(.top, 30)
                
                Text("انتظر قليلاً...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else if let error = viewModel.errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text(error)
                    .font(.body)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            if viewModel.isSearching {
                Button {
                    Task {
                        await viewModel.cancelSearch()
                        dismiss()
                    }
                } label: {
                    Text("إلغاء")
                        .foregroundColor(.red)
                }
                .padding()
            } else if viewModel.errorMessage != nil {
                Button {
                    Task {
                        await viewModel.findMatch()
                    }
                } label: {
                    Text("حاول مرة أخرى")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
                .padding(.horizontal, 40)
            }
            
            Spacer()
                .frame(height: 50)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .navigationTitle("البحث")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $viewModel.matchedChatId) { chatId in
            ChatView(chatId: chatId, currentUserId: userId)
        }
        .task {
            await viewModel.findMatch()
        }
    }
}
