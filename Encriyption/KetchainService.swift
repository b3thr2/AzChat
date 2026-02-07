//
//  KetchainService.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//

import Foundation
import Security

class KeychainService {
    
    static func savePrivateKey(_ key: String, for chatId: String) throws {
        let data = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "chat_\(chatId)_privateKey",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }
    
    static func getPrivateKey(for chatId: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "chat_\(chatId)_privateKey",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }
        
        return key
    }
    
    static func deletePrivateKey(for chatId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "chat_\(chatId)_privateKey"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: LocalizedError {
    case saveFailed
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "فشل حفظ المفتاح"
        case .notFound:
            return "المفتاح غير موجود"
        }
    }
}
