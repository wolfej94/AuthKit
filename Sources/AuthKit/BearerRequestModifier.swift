//
//  BearerRequestModifier.swift
//  
//
//  Created by James Wolfe on 07/06/2023.
//

import Foundation
import NetShears

struct BearerRequestModifier: RequestEvaluatorModifier, Equatable {
    
    // MARK: - Variables
    let url: URL
    let token: String
    
    // MARK: - RequestEvaluatorModifier
    func modify(request: inout URLRequest) {
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    func isActionAllowed(urlRequest: URLRequest) -> Bool {
        return urlRequest.url?.hasSameDomain(as: url) ?? false
    }
    
    static var storeFileName: String {
        "Header.txt"
    }
    
}



