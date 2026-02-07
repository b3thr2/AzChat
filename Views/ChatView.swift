//
//  ChatView.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//
import SwiftUI
import PhotosUI

struct ChatView: View {
    let chatId: String
    let currentUserId: String
    
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showEndChatAlert = false
    @Environment(\.dismiss) private var dismiss
    
    init(chatId: String, currentUserId: String) {
        self.chatId = chatId
        self.currentUserId = currentUserId
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatId: chatId, currentUserId: currentUserId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // قائمة الرسائل
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isCurrentUser: message.senderId == currentUserId
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // شريط الإدخال
            HStack(spacing: 12) {
                Button {
                    showImagePicker = true
                } label: {
                    Image(systemName: "photo.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                TextField("اكتب رسالة...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .environment(\.layoutDirection, .rightToLeft)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty || viewModel.isSending)
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .environment(\.layoutDirection, .rightToLeft)
        .navigationTitle("محادثة")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEndChatAlert = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("إنهاء المحادثة", isPresented: $showEndChatAlert) {
            Button("إلغاء", role: .cancel) { }
            Button("إنهاء", role: .destructive) {
                Task {
                    await viewModel.endChat()
                    dismiss()
                }
            }
        } message: {
            Text("هل تريد إنهاء هذه المحادثة؟")
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                Task {
                    await viewModel.sendImage(image)
                    selectedImage = nil
                }
            }
        }
    }
    
    func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        Task {
            await viewModel.sendTextMessage(text)
            messageText = ""
        }
    }
}
