//
//  Session.swift
//  StalkCentral
//
//  Created by Kevin Sullivan on 4/2/20.
//  Copyright © 2020 Kevin Sullivan. All rights reserved.
//

import SwiftUI

import Firebase
import FirebaseAuth

class Session: ObservableObject {
    
    static let shared = Session()
    
    @Published private(set) var user: User?
    @Published private(set) var isLoggedIn = false
    
    private var isFirstTransition = true
    
    func listen(window: UIWindow?) {
        _ = Auth.auth().addStateDidChangeListener { auth, user in
            let targetVC: UIHostingController<AnyView>
            
            if let user = user {
                print("User logged in: \(user)")
                self.user = User(uid: user.uid, email: user.email)
                self.isLoggedIn = true
                
                targetVC = .init(rootView: AnyView(ContentView()))
            } else {
                print("User logged out")
                self.user = nil
                self.isLoggedIn = false
                
                targetVC = .init(rootView: AnyView(LoginView()))
            }

            window?.rootViewController = targetVC
            
            if !self.isFirstTransition, let window = window {
                UIView.transition(
                    with: window,
                    duration: 0.3,
                    options: [.transitionCrossDissolve],
                    animations: nil
                )
            }
            
            self.isFirstTransition = false
        }
    }
    
    func logInAnonymously(_ completion: AuthDataResultCallback?) {
        Auth.auth().signInAnonymously(completion: completion)
    }
    
    func logOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            user = nil
        } catch {
            print("Failed to sign out: \(error.localizedDescription)")
        }
    }
}
