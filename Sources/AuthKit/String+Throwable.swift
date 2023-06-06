//
//  String+Throwable.swift
//  
//
//  Created by James Wolfe on 06/06/2023.
//

import Foundation

extension String: LocalizedError {
    
    public var errorDescription: String? { self}
}
