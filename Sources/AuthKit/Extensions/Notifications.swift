//
//  Notifications.swift
//  
//
//  Created by James Wolfe on 06/06/2023.
//

import Foundation

public extension Notification.Name {
    
    static let authenticated: Notification.Name = .init("authenticated")
    static let unauthenticated: Notification.Name = .init("unauthenticated")
}
