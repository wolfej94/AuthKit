//
//  View+Listeners.swift
//  
//
//  Created by James Wolfe on 07/06/2023.
//

import SwiftUI

public extension View {
    
    @ViewBuilder func onAuthenticate(_ action: @escaping () -> Void) -> some View {
        self
            .onAppear {
                NotificationCenter.default.addObserver(forName: .authenticated, object: nil, queue: .main) { _ in
                    action()
                }
            }
    }
    
    @ViewBuilder func onUnauthenticate(_ action: @escaping () -> Void) -> some View {
        self
            .onAppear {
                NotificationCenter.default.addObserver(forName: .unauthenticated, object: nil, queue: .main) { _ in
                    action()
                }
            }
    }
    
}
