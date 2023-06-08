//
//  SanctumAuthResponse.swift
//  
//
//  Created by James Wolfe on 06/06/2023.
//

import Foundation

struct SanctumAuthResponse: Decodable {
    
    // MARK: - Variables
    let token: String
    
    // MARK: - Coding Keys
    private enum ParentKeys: String, CodingKey {
        case data
    }
    
    private enum CodingKeys: String, CodingKey {
        case token
    }
    
    // MARK: - Decodable
    init(from decoder: Decoder) throws {
        let parent = try decoder.container(keyedBy: ParentKeys.self)
        let container = try parent.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        self.token = try container.decode(String.self, forKey: .token)
    }
}
