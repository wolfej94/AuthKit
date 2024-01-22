//
//  AuthKit.swift
//
//
//  Created by James Wolfe on 05/06/2023.
//

import Foundation
import Valet
import CryptoSwift
import NetShears

public class AuthKit {
    
    // MARK: - Variables
    private let bundle: String
    private let prompt: String
    private let baseURL: URL
    private var method: AuthenticationMethod
    
    internal var bearerToken: String? {
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
        switch method {
        case .basic:
            let modifier = NetShears.shared.modifiedList().first(where: { $0 is BasicRequestModifier }) as? BasicRequestModifier
            return modifier != nil && !modifier!.email.isEmpty && !modifier!.password.isEmpty
        default:
            return bearerToken != nil
        }
    }
    
    // MARK: - Initializers
    public init(bundle: String, prompt: String, method: AuthenticationMethod, baseURL: URL) {
        self.bundle = bundle
        self.prompt = prompt
        self.method = method
        self.baseURL = baseURL
        setupBearerAuthorization()
    }
    
    // MARK: - Authenticate
    /// Authenticates a user using email and password
    /// - Parameters:
    ///   - path: URL path the refresh token endpoint can be found at
    ///   - email: Email for the user
    ///   - password: Password for the user
    public func authenticate(path: String, email: String, password: String) async throws {
        switch method {
        case .oAuth(let clientId, let clientSecret):
            try await authenticate(path: path, body: .init(username: email, password: password, clientID: clientId, clientSecret: clientSecret))
        case .featherweight:
            try await authenticate(path: path, body: .init(email: email, password: password))
        case .basic:
            self.method = .basic
            self.setupBasicAuthorization(email: email, password: password)
        }
        NotificationCenter.default.post(name: .authenticated, object: nil)
    }
    
    // MARK: - Authenticate With Response
    /// Authenticates a user and returns a custom response of the specified type.
    ///
    /// - Parameters:
    ///   - path: URL path the refresh token endpoint can be found at
    ///   - email: Email for the user
    ///   - password: Password for the user
    ///   - responseType: The custom `Decodable` type to decode the response into.
    /// - Returns: An instance of the specified `responseType` if successful, otherwise `nil`.
    /// - Throws: An error if the authentication request fails or if the response cannot be decoded.
    public func authenticateWithResponse<CustomAuthResponse: Decodable>(path: String, email: String, password: String, responseType: CustomAuthResponse.Type) async throws -> CustomAuthResponse? {
        return try await authenticate(path: path, body: .init(email: email, password: password), responseType: responseType)
    }

    private func authenticate(path: String, body: OAuthAuthRequest) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await withCheckedThrowingContinuation({ continuation in
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                do {
                    guard error == nil else { throw error! }
                    guard let urlResponse = response as? HTTPURLResponse else { throw "Invalid Response" }
                    if !Array(200..<300).contains(urlResponse.statusCode) { throw "Email address or password was incorrect." }
                    guard let data = data else { throw "Invalid Response" }
                    let response = try JSONDecoder().decode(OAuthAuthResponse.self, from: data)
                    try self?.keychain?.setString(response.accessToken, forKey: "bearer_token")
                    self?.setupBearerAuthorization()
                    try self?.enclave?.setString(response.refreshToken, forKey: "refresh_token")
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        })
    }
    
    private func authenticate(path: String, body: FeatherweightAuthRequest) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await withCheckedThrowingContinuation({ continuation in
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                do {
                    guard error == nil else { throw error! }
                    guard let urlResponse = response as? HTTPURLResponse else { throw "Invalid Response" }
                    if !Array(200..<300).contains(urlResponse.statusCode) { throw "Email address or password was incorrect." }
                    guard let data = data else { throw "Invalid Response" }
                    let response = try JSONDecoder().decode(FeatherweightAuthResponse.self, from: data)
                    try self?.keychain?.setString(response.token, forKey: "bearer_token")
                    self?.setupBearerAuthorization()
                    try self?.enclave?.removeObject(forKey: "refresh_token")
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        })
    }
    
    private func authenticate<Response: Decodable>(path: String, body: FeatherweightAuthRequest, responseType: Response.Type) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await withCheckedThrowingContinuation({ continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                do {
                    guard error == nil else { throw error! }
                    guard let urlResponse = response as? HTTPURLResponse else { throw "Invalid Response" }
                    if !Array(200..<300).contains(urlResponse.statusCode) { throw "Email address or password was incorrect." }
                    guard let data = data else { throw "Invalid Response" }
                    let response = try JSONDecoder().decode(responseType, from: data)
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        })
    }

    // MARK: - Reauthenticate
    /// Reauthenticates user using oAuth refresh token
    /// - Parameters:
    ///   - url: URL the refresh token endpoint can be found at
    public func reauthenticate(path: String) async throws {
        guard case .oAuth(let clientID, let clientSecret) = method else {
            throw "Method only available for oAuth flow"
        }
        guard let token = refreshToken else {
            try? unauthenticate()
            return
        }
        let body = OAuthRefreshRequest(refreshToken: token, clientID: clientID, clientSecret: clientSecret)
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await withCheckedThrowingContinuation({ continuation in
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                do {
                    guard error == nil else { throw error! }
                    guard let urlResponse = response as? HTTPURLResponse else { throw "Invalid Response" }
                    if !Array(200..<300).contains(urlResponse.statusCode) { throw "Refresh token is invalid" }
                    guard let data = data else { throw "Invalid Response" }
                    let response = try JSONDecoder().decode(OAuthAuthResponse.self, from: data)
                    try self?.keychain?.setString(response.accessToken, forKey: "bearer_token")
                    try self?.enclave?.setString(response.refreshToken, forKey: "refresh_token")
                    self?.setupBearerAuthorization()
                    continuation.resume()
                } catch {
                    try? self?.unauthenticate()
                    continuation.resume(throwing: error)
                }
            }.resume()
        })
    }
    
    // MARK: - Unauthenticate
    /// Unauthenticates the user
    public func unauthenticate() throws {
        try enclave?.removeAllObjects()
        try keychain?.removeAllObjects()
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
    
    // MARK: - Authorization
    private func setupBearerAuthorization() {
        NetShears.shared.startInterceptor()
        for interceptor in NetShears.shared.modifiedList().enumerated() where interceptor.element is BearerRequestModifier {
            NetShears.shared.removeModifier(at: interceptor.offset)
        }
        guard let token = bearerToken else { return }
        NetShears.shared.modify(modifier: BearerRequestModifier(url: baseURL, token: token))
    }
    
    private func setupBasicAuthorization(email: String, password: String) {
        NetShears.shared.startInterceptor()
        for interceptor in NetShears.shared.modifiedList().enumerated() where interceptor.element is BasicRequestModifier {
            NetShears.shared.removeModifier(at: interceptor.offset)
        }
        NetShears.shared.modify(modifier: BasicRequestModifier(url: baseURL, email: email, password: password))
    }
    
    /// Manually sets auth token
    /// - Parameter token:
    public func setBearerToken(to token: String) throws {
        try keychain?.setString(token, forKey: "bearer_token")
        setupBearerAuthorization()
        NotificationCenter.default.post(name: .authenticated, object: nil)
    }
    
    /// Manually sets refresh token
    /// - Parameter refreshToken:
    public func setRefreshToken(to refreshToken: String) throws {
        try enclave?.setString(refreshToken, forKey: "refresh_token")
    }

    /// Get refresh token
    public func getRefreshToken() -> String? {
        guard let token = refreshToken else {
            try? unauthenticate()
            return nil
        }
        return token
    }

}
