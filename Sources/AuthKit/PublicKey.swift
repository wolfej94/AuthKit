//
//  PublicKey.swift
//  
//
//  Created by James Wolfe on 06/06/2023.
//

import Foundation
import CryptoSwift
import Valet

public struct PublicKey: Identifiable, Encodable {
    
    // MARK: - Variables
    public let id: UUID
    private let privateKey: RSA
    public var publicKey: String? {
        return try? privateKey.publicKeyExternalRepresentation().base64EncodedString()
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case publicKey = "public_key"
    }
    
    // MARK: - Initializers
    init() throws {
        self.id = .init()
        self.privateKey = try .init(keySize: 512)
    }
    
    private init(id: UUID, privateKey: RSA) {
        self.id = id
        self.privateKey = privateKey
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(publicKey, forKey: .publicKey)
        try container.encode(id, forKey: .id)
    }
    
    // MARK: - Utilities
    public func save(toEnclave enclave: SecureEnclaveValet) throws {
        try enclave.setObject(privateKey.publicKeyExternalRepresentation(), forKey: id.uuidString)
    }
    
    public static func load(id: UUID, fromEnclave enclave: SecureEnclaveValet, prompt: String) throws -> PublicKey {
        let raw = try enclave.object(forKey: id.uuidString, withPrompt: prompt)
        return try .init(id: id, privateKey: .init(rawRepresentation: raw))
    }
    
    public func sign(challenge: String) throws -> String {
        guard let data = challenge.data(using: .utf8) else { throw "Invalid challenge encoding" }
        return try privateKey.sign(data.bytes).toBase64()
    }
    
}
