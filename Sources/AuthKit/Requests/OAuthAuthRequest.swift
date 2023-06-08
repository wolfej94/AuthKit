//
//  OAuthAuthRequest.swift
//  
//
//  Created by James Wolfe on 06/06/2023.
//

import Foundation

internal struct OAuthAuthRequest: Encodable {
    
    // MARK: - Variables
    let username: String
    let password: String
    let clientID: String
    let clientSecret: String
    let grantType = "password"
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case username
        case password
        case clientID = "client_id"
        case clientSecret = "client_secret"
        case grantType = "grant_type"
    }
    
}
