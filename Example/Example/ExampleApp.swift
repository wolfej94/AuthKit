//
//  ExampleApp.swift
//  Example
//
//  Created by James Wolfe on 07/06/2023.
//

import SwiftUI
import AuthKit

@main
struct ExampleApp: App {
    
    // MARK: - Variables
    @State var isAuthenticated = Configuration.auth.isAuthenticated
    
    // MARK: - Views
    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                ContentView()
                    .onUnauthenticate {
                        withAnimation { isAuthenticated = false }
                    }
            } else {
                LoginView()
                    .onAuthenticate {
                        withAnimation { isAuthenticated = true }
                    }
            }
        }
    }
}
