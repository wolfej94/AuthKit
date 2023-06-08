//
//  ContentView.swift
//  Example
//
//  Created by James Wolfe on 07/06/2023.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Variables
    @State var state: UIState = .initial
    
    // MARK: - Actions
    func logout() {
        withAnimation { state = .initial } 
        do {
            try Configuration.auth.unauthenticate()
        } catch {
            withAnimation {
                state = .error(message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Views
    var body: some View {
        VStack(spacing: 5) {
            Spacer()
            Button(action: logout, label: {
                HStack {
                    Spacer()
                    Text("ContentView.LogoutButton.Title")
                        .foregroundColor(.white)
                    Spacer()
                }
                .frame(height: 50)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            })
            if case .error(let message) = state {
                HStack {
                    Text(message)
                        .foregroundColor(.red)
                        .font(.caption)
                    Spacer()
                }
            }
            Spacer()
        }
        .onAppear {
            URLSession.shared.dataTask(with: .init(url: Configuration.url)) { data, response, error in
                print("awd")
            }.resume()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
