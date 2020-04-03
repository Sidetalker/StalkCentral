//
//  LoginDelegates.swift
//  StalkCentral
//
//  Created by Kevin Sullivan on 4/2/20.
//  Copyright © 2020 Kevin Sullivan. All rights reserved.
//

import UIKit
import AuthenticationServices

import FirebaseAuth

class LoginDelegates: NSObject {
    
    private let loginResult: (Result<Void, Error>) -> Void
    private weak var window: UIWindow!

    // Unhashed nonce.
    fileprivate var currentNonce: String?
    
    init(window: UIWindow?, onLoggedIn: @escaping (Result<Void, Error>) -> Void) {
        self.window = window
        self.loginResult = onLoggedIn
    }
    
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
}

extension LoginDelegates: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error signing in to Firebase with nonce from Apple sign in: \(error.localizedDescription)")
                    return
                }
                
                print("Logged into Firebase with Apple sign in")
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError = ASAuthorizationError(_nsError: error as NSError)
        switch authError.code {
        case .canceled: print("Cancelled sign in")
        case .unknown: print("Unknown error during sign in")
        case .invalidResponse: print("Invalid response during sign in")
        case .notHandled: print("Unhandled sign in event")
        case .failed: print("Sign in failed")
        @unknown default: print("Sign in failed with code: \(authError.code)")
        }
    }
}

extension LoginDelegates: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return window
    }
}
