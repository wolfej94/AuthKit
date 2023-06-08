//
//  LoginView.swift
//  Example
//
//  Created by James Wolfe on 07/06/2023.
//

import SwiftUI

struct LoginView: View {
    
    // MARK: - Variables
    @State var email = ""
    @State var password = ""
    @State var state: UIState = .initial
    @FocusState var focus: Field?
    
    // MARK: - Actions
    func login() {
        withAnimation { state = .loading }
        Task {
            do {
                try await Configuration.auth.authenticate(
                    path: "oauth/token",
                    email: email,
                    password: password
                )
            } catch {
                await MainActor.run {
                    state = .error(message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Views
    var body: some View {
        VStack {
            Spacer()
            TextField("LoginView.EmailField.Placeholder", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .focused($focus, equals: .email)
            VStack(spacing: 5) {
                SecureField("LoginView.PasswordField.Placeholder", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.password)
                    .keyboardType(.default)
                    .focused($focus, equals: .password)
                if case .error(let message) = state {
                    HStack {
                        Text(message)
                            .foregroundColor(.red)
                            .font(.caption)
                        Spacer()
                    }
                }
            }
            .padding(.bottom)
            Button(action: login, label: {
                HStack {
                    Spacer()
                    if state == .loading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("LoginView.LoginButton.Title")
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .frame(height: 50)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            })
        }
        .padding()
        .onChange(of: focus, perform: { newValue in
            if newValue != nil {
                withAnimation {
                    state = .initial
                }
            }
        })
        .onAppear {
            email = ""
            password = ""
            state = .initial
        }
    }
}

extension LoginView {
    
    enum Field {
        
        // MARK: - Cases
        case email
        case password
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
