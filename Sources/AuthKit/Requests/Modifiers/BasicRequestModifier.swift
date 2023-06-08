//
//  BasicRequestModifier.swift
//  
//
//  Created by James Wolfe on 08/06/2023.
//

import Foundation
import NetShears

internal struct BasicRequestModifier: RequestEvaluatorModifier, Equatable {
    
    // MARK: - Variables
    let url: URL
    let email: String
    let password: String
    
    // MARK: - RequestEvaluatorModifier
    func modify(request: inout URLRequest) {
        guard let data = "\(email):\(password)".data(using: .utf8) else { return }
        request.addValue("Basic \(data.base64EncodedString())", forHTTPHeaderField: "Authorization")
    }
    
    func isActionAllowed(urlRequest: URLRequest) -> Bool {
        return urlRequest.url?.hasSameDomain(as: url) ?? false
    }
    
    static var storeFileName: String {
        "Header.txt"
    }
    
}



