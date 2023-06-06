//
//  AuthenticationMethod.swift
//  
//
//  Created by James Wolfe on 05/06/2023.
//

import Foundation

public enum AuthenticationMethod {
    
    // MARK: - Cases
    case sanctum(email: String, password: String)
    case passport(clientId: String, clientSecret: String)
}
