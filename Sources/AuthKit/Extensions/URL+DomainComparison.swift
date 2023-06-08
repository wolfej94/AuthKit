//
//  URL+DomainComparison.swift
//  
//
//  Created by James Wolfe on 07/06/2023.
//

import Foundation

internal extension URL {
    
    func hasSameDomain(as url: URL) -> Bool {
        guard let lhs = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return false }
        guard let rhs = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        return lhs.host == rhs.host
    }
    
}
