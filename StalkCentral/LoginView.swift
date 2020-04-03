//
//  LoginView.swift
//  StalkCentral
//
//  Created by Kevin Sullivan on 4/2/20.
//  Copyright © 2020 Kevin Sullivan. All rights reserved.
//

import SwiftUI
import AuthenticationServices
import CryptoKit

class PassportTitleProvider {
    
}

struct SignInWithAppleView: UIViewRepresentable {
    
    var colorScheme: ColorScheme
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        var style: ASAuthorizationAppleIDButton.Style
        
        switch colorScheme {
        case .light: style = .black
        case .dark: style = .white
        @unknown default:
            style = .black
            print("Unknown ColorScheme \(colorScheme)")
        }
        
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: style)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
}

struct User {
    var uid: String
    var email: String?
    var title: (String, String)?
}

struct WindowKey: EnvironmentKey {
    struct Value {
        weak var value: UIWindow?
    }
    
    static let defaultValue = Value(value: nil)
}

extension EnvironmentValues {
    var window: UIWindow? {
        get { return self[WindowKey.self].value }
        set { self[WindowKey.self] = .init(value: newValue) }
    }
}

struct LoginView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.window) var window: UIWindow?
    
    @State var delegates: LoginDelegates!
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer().frame(height: 100)
            Text("StalkCentral")
                .fontWeight(.bold)
                .font(.largeTitle)
            Spacer()
            VStack(alignment: .center, spacing: 20) {
                // This doesn't update on color scheme change and I don't understand why
                //                SignInWithAppleView(colorScheme: colorScheme)
                //                    .frame(width: 200, height: 44)
                //                    .onTapGesture(perform: showAppleLogin)
                
                if colorScheme == .dark {
                    SignInWithAppleView(colorScheme: .dark)
                        .frame(width: 200, height: 44)
                        .onTapGesture(perform: showAppleLogin)
                        .allowsHitTesting(!isLoading)
                } else {
                    SignInWithAppleView(colorScheme: .light)
                        .frame(width: 200, height: 44)
                        .onTapGesture(perform: showAppleLogin)
                        .allowsHitTesting(!isLoading)
                }
                
                Button(action: {
                    self.performAnonymousLogin()
                }, label: {
                    Text("Continue as Guest")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }).disabled(isLoading)
            }
            Spacer().frame(height: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(colorScheme == .dark ?
            Color.black.edgesIgnoringSafeArea(.all) :
            Color.white.edgesIgnoringSafeArea(.all))
        .onAppear(perform: setupAppleLogin)
    }
    
    private func setupAppleLogin() {
        delegates = LoginDelegates(window: window) { result in
            switch result {
            case .success: break
            case .failure(let error):
                print("Failed to sign in with Apple: \(error.localizedDescription)")
            }
        }
        
        let requests = [
          getAppleIDProviderRequest(),
          ASAuthorizationPasswordProvider().createRequest()
        ]
        
        triggerAppleSignIn(with: requests)
    }
    
    private func showAppleLogin() {
        triggerAppleSignIn(with: [getAppleIDProviderRequest()])
    }
    
    private func getAppleIDProviderRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = delegates.generateNonce()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)
        return request
    }
    
    private func triggerAppleSignIn(with requests: [ASAuthorizationRequest]) {
        
        
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = delegates
        authorizationController.presentationContextProvider = delegates
        authorizationController.performRequests()
    }
    
    private func performAnonymousLogin() {
        isLoading = true
        
        Session.shared.logInAnonymously { result, error in
            self.isLoading = false
                
            if let error = error {
                print("Error logging in anonymously: \(error.localizedDescription)")
                return
            }
            
            print("Logged in anonymously")
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environment(\.colorScheme, .dark)
    }
}
