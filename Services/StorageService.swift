//
//  StorageService.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//
import Foundation
import Supabase
import UIKit
import CryptoKit

class StorageService {
    private let supabase = SupabaseConfig.shared.client
    
    func uploadEncryptedImage(_ image: UIImage, chatId: String, symmetricKey: SymmetricKey) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.invalidImage
        }
        
        // تشفير البيانات
        let encryptedData = try EncryptionService.encryptImage(imageData, using: symmetricKey)
        
        let fileName = "\(chatId)/\(UUID().uuidString).enc"
        
        // رفع الملف
        _ = try await supabase.storage
            .from("Chat-Images")
            .upload(
                path: fileName,
                file: encryptedData,
                options: FileOptions(contentType: "application/octet-stream")
            )
        
        // الحصول على الرابط
        let url = try supabase.storage
            .from("Chat-Images")
            .getPublicURL(path: fileName)
        
        return url.absoluteString
    }
    
    func downloadAndDecryptImage(from urlString: String, using symmetricKey: SymmetricKey) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw StorageError.invalidURL
        }
        
        // تحميل البيانات المشفرة
        let (encryptedData, _) = try await URLSession.shared.data(from: url)
        
        // فك التشفير
        let decryptedData = try EncryptionService.decryptImage(encryptedData, using: symmetricKey)
        
        guard let image = UIImage(data: decryptedData) else {
            throw StorageError.invalidImage
        }
        
        return image
    }
}

enum StorageError: LocalizedError {
    case invalidImage
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "الصورة غير صالحة"
        case .invalidURL:
            return "الرابط غير صالح"
        }
    }
}
