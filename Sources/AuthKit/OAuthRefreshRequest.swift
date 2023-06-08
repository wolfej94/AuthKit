//
//  OAuthAuthRequest.swift
//  
//
//  Created by James Wolfe on 06/06/2023.
//

import Foundation

internal struct OAuthRefreshRequest: Encodable {
    
    // MARK: - Variables
    let refreshToken: String
    let clientID: String
    let clientSecret: String
    let grantType = "refresh_token"
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
        case clientID = "client_id"
        case clientSecret = "client_secret"
        case grantType = "grant_type"
    }
    
}
