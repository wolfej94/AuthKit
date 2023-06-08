//
//  UIState.swift
//  Example
//
//  Created by James Wolfe on 07/06/2023.
//

import SwiftUI

enum UIState: Equatable {
    
    // MARK: - Cases
    case initial
    case loading
    case error(message: String)
    
}
