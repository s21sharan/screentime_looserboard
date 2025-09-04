//
//  AuthTest.swift
//  screentime_lboard
//
//  Test file to verify Supabase authentication
//

import SwiftUI

struct AuthTest: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var testResult = "Not tested yet"
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AUTHENTICATION TEST")
                .font(.system(size: 20, weight: .black))
                .tracking(1.5)
            
            if isLoading {
                ProgressView()
            } else {
                Text(testResult)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Button("Test Sign Up") {
                testSignUp()
            }
            .buttonStyle(.borderedProminent)
            .tint(.black)
            
            Button("Test Sign In") {
                testSignIn()
            }
            .buttonStyle(.borderedProminent)
            .tint(.gray)
            
            if authManager.isAuthenticated {
                Button("Sign Out") {
                    authManager.logOut()
                    testResult = "Signed out successfully"
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
    }
    
    func testSignUp() {
        isLoading = true
        Task {
            do {
                let testUsername = "testuser\(Int.random(in: 1000...9999))"
                let testPassword = "testpass123"
                
                try await authManager.signUp(username: testUsername, password: testPassword)
                testResult = "Sign up successful! Username: \(testUsername)"
            } catch {
                testResult = "Sign up failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    func testSignIn() {
        isLoading = true
        Task {
            do {
                // Try to sign in with a known test account
                try await authManager.logIn(username: "testuser", password: "testpass123")
                testResult = "Sign in successful!"
            } catch {
                testResult = "Sign in failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}