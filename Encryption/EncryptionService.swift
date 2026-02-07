//
//  EncryptionService.swift
//  
//
//  Created by Amal  on 19/08/1447 AH.
//

import Foundation
import CryptoKit

class EncryptionService {
    
    // MARK: - Key Generation
    
    static func generateSymmetricKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    static func keyToData(_ key: SymmetricKey) -> Data {
        return key.withUnsafeBytes { Data($0) }
    }
    
    static func dataToKey(_ data: Data) -> SymmetricKey {
        return SymmetricKey(data: data)
    }
    
    // MARK: - Text Encryption/Decryption
    
    static func encryptText(_ text: String, using key: SymmetricKey) throws -> String {
        guard let data = text.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        return combined.base64EncodedString()
    }
    
    static func decryptText(_ encryptedText: String, using key: SymmetricKey) throws -> String {
        guard let data = Data(base64Encoded: encryptedText) else {
            throw EncryptionError.invalidInput
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        guard let text = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        
        return text
    }
    
    // MARK: - Image Encryption/Decryption
    
    static func encryptImage(_ imageData: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(imageData, using: key)
        
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        return combined
    }
    
    static func decryptImage(_ encryptedData: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return decryptedData
    }
    
    // MARK: - Key Exchange using Curve25519
    
    static func generateKeyPair() -> (privateKey: Curve25519.KeyAgreement.PrivateKey,
                                       publicKey: Curve25519.KeyAgreement.PublicKey) {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey
        return (privateKey, publicKey)
    }
    
    static func deriveSymmetricKey(privateKey: Curve25519.KeyAgreement.PrivateKey,
                                   publicKey: Curve25519.KeyAgreement.PublicKey) throws -> SymmetricKey {
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
        
        return sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )
    }
    
    static func publicKeyToString(_ publicKey: Curve25519.KeyAgreement.PublicKey) -> String {
        return publicKey.rawRepresentation.base64EncodedString()
    }
    
    static func stringToPublicKey(_ string: String) throws -> Curve25519.KeyAgreement.PublicKey {
        guard let data = Data(base64Encoded: string) else {
            throw EncryptionError.invalidKey
        }
        return try Curve25519.KeyAgreement.PublicKey(rawRepresentation: data)
    }
    
    static func privateKeyToString(_ privateKey: Curve25519.KeyAgreement.PrivateKey) -> String {
        return privateKey.rawRepresentation.base64EncodedString()
    }
    
    static func stringToPrivateKey(_ string: String) throws -> Curve25519.KeyAgreement.PrivateKey {
        guard let data = Data(base64Encoded: string) else {
            throw EncryptionError.invalidKey
        }
        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
    }
}

// MARK: - Errors

enum EncryptionError: LocalizedError {
    case invalidInput
    case encryptionFailed
    case decryptionFailed
    case invalidKey
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "بيانات الإدخال غير صالحة"
        case .encryptionFailed:
            return "فشل التشفير"
        case .decryptionFailed:
            return "فشل فك التشفير"
        case .invalidKey:
            return "المفتاح غير صالح"
        }
    }
}
