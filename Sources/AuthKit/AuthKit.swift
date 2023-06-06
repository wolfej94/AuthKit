//
//  AuthKit.swift
//
//
//  Created by James Wolfe on 05/06/2023.
//

import Foundation
import Valet
import CryptoSwift

public struct AuthKit {
    
    // MARK: - Variables
    private let bundle: String
    private let prompt: String
    private let method: AuthenticationMethod
    
    private var bearerToken: String? {
        return try? keychain?.string(forKey: "bearer_token")
    }
    
    private var refreshToken: String? {
        return try? enclave?.string(forKey: "refresh_token", withPrompt: prompt)
    }
    
    private var enclave: SecureEnclaveValet? {
        guard let identifier = Identifier(nonEmpty: bundle) else { return nil }
        return SecureEnclaveValet.valet(with: identifier, accessControl: .userPresence)
    }
    
    private var keychain: Valet? {
        guard let identifier = Identifier(nonEmpty: bundle) else { return nil }
        return Valet.valet(with: identifier, accessibility: .afterFirstUnlockThisDeviceOnly)
    }
    
    /// Indicates whether a user is authenticated or not
    public var isAuthenticated: Bool {
        return bearerToken != nil
    }
    
    // MARK: - Initializers
    public init(bundle: String, prompt: String, method: AuthenticationMethod) {
        self.bundle = bundle
        self.prompt = prompt
        self.method = method
    }
    
    // MARK: - Authenticate
    /// Authenticates a user using email and password
    /// - Parameters:
    ///   - url: URL the refresh token endpoint can be found at
    ///   - email: Email for the user
    ///   - password: Password for the user
    public func authenticate(url: URL, email: String, password: String) async throws {
        switch method {
        case .passport(let clientId, let clientSecret):
            try await authenticate(url: url, body: .init(email: email, password: password, clientID: clientId, clientSecret: clientSecret))
        case .sanctum(let email, let password):
            try await authenticate(url: url, body: .init(email: email, password: password))
        }
        NotificationCenter.default.post(name: .authenticated, object: nil)
    }
    
    private func authenticate(url: URL, body: PassportAuthRequest) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await withCheckedThrowingContinuation({ continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                do {
                    guard error == nil else { throw error! }
                    guard let data = data else { throw "Invalid Response" }
                    let response = try JSONDecoder().decode(PassportAuthResponse.self, from: data)
                    try keychain?.setString(response.accessToken, forKey: "bearer_token")
                    try enclave?.setString(response.refreshToken, forKey: "refresh_token")
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        })
    }
    
    private func authenticate(url: URL, body: SanctumAuthRequest) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await withCheckedThrowingContinuation({ continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                do {
                    guard error == nil else { throw error! }
                    guard let data = data else { throw "Invalid Response" }
                    let response = try JSONDecoder().decode(SanctumAuthResponse.self, from: data)
                    try keychain?.setString(response.token, forKey: "bearer_token")
                    try enclave?.removeObject(forKey: "refresh_token")
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        })
    }
    
    // MARK: - Reauthenticate
    /// Reauthenticates user using passport refresh token
    /// - Parameters:
    ///   - url: URL the refresh token endpoint can be found at
    ///   - clientID: Client ID for the passport configuration
    ///   - clientSecret: Client secret for the passport configuration
    public func reauthenticate(url: URL, clientID: String, clientSecret: String) async throws {
        guard let token = refreshToken else { return }
        let body = PassportRefreshRequest(refreshToken: token, clientID: clientID, clientSecret: clientSecret)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await withCheckedThrowingContinuation({ continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                do {
                    guard error == nil else { throw error! }
                    guard let data = data else { throw "Invalid Response" }
                    let response = try JSONDecoder().decode(SanctumAuthResponse.self, from: data)
                    try keychain?.setString(response.token, forKey: "bearer_token")
                    try enclave?.removeObject(forKey: "refresh_token")
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        })
    }
    
    // MARK: - Unauthenticate
    /// Unauthenticates the user
    public func unauthenticatae() throws {
        try enclave?.removeObject(forKey: "refresh_token")
        try enclave?.removeObject(forKey: "bearer_token")
        if let id = try keychain?.string(forKey: "rsa_key_id") {
            try enclave?.removeObject(forKey: id)
            try keychain?.removeObject(forKey: "rsa_key_id")
        }
        NotificationCenter.default.post(name: .unauthenticated, object: nil)
    }
    
    // MARK: - Public Key
    /// Generated public key pair and saves it for use in verification later
    public func generateKeyPair() throws -> PublicKey {
        guard let enclave = enclave else { throw "Could not access secure enclave" }
        if let id = try keychain?.string(forKey: "rsa_key_id"), let uuid = UUID(uuidString: id) {
            return try PublicKey.load(id: uuid, fromEnclave: enclave, prompt: prompt)
        } else {
            let key = try PublicKey()
            try key.save(toEnclave: enclave)
            try keychain?.setString(key.id.uuidString, forKey: "rsa_key_id")
            return key
        }
    }
    
    /// Signs code challenge string from server generated with public key
    /// - Parameter challenge: Challenge from server generated with public key
    /// - Returns: Signed code challenge to be returned to the server
    public func sign(challenge: String) throws -> String {
        guard let enclave = enclave else { throw "Could not access secure enclave" }
        guard let id = try keychain?.string(forKey: "rsa_key_id"), let uuid = UUID(uuidString: id) else { throw "Key ID not found" }
        let key = try PublicKey.load(id: uuid, fromEnclave: enclave, prompt: prompt)
        return try key.sign(challenge: challenge)
    }
}
