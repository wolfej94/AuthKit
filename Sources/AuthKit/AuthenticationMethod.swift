//
//  AuthenticationMethod.swift
//  
//
//  Created by James Wolfe on 05/06/2023.
//

import Foundation

public enum AuthenticationMethod {
    
    // MARK: - Cases
    case featherweight
    case oAuth(clientId: String, clientSecret: String)
    case basic
}
