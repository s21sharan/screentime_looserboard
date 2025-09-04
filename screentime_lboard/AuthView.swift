//
//  AuthView.swift
//  screentime_lboard
//
//  Created by Sharan Subramanian on 9/4/25.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var isSignUp = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Logo Section
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 60, weight: .black))
                        .foregroundColor(.black)
                    
                    Text("SCREENSAWAY")
                        .font(.system(size: 28, weight: .black))
                        .tracking(2.0)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Auth Toggle
                HStack(spacing: 0) {
                    Button(action: { isSignUp = true }) {
                        Text("SIGN UP")
                            .font(.system(size: 14, weight: isSignUp ? .black : .bold))
                            .tracking(1.0)
                            .foregroundColor(isSignUp ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                VStack {
                                    Spacer()
                                    if isSignUp {
                                        Rectangle()
                                            .fill(Color.black)
                                            .frame(height: 3)
                                    }
                                }
                            )
                    }
                    
                    Button(action: { isSignUp = false }) {
                        Text("LOG IN")
                            .font(.system(size: 14, weight: !isSignUp ? .black : .bold))
                            .tracking(1.0)
                            .foregroundColor(!isSignUp ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                VStack {
                                    Spacer()
                                    if !isSignUp {
                                        Rectangle()
                                            .fill(Color.black)
                                            .frame(height: 3)
                                    }
                                }
                            )
                    }
                }
                .padding(.horizontal)
                
                // Form Fields
                VStack(spacing: 20) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("USERNAME")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(.secondary)
                        
                        TextField("", text: $username)
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(4)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PASSWORD")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(.secondary)
                        
                        SecureField("", text: $password)
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(4)
                    }
                    
                    // Submit Button
                    Button(action: handleAuth) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.black)
                                .cornerRadius(4)
                        } else {
                            Text(isSignUp ? "CREATE ACCOUNT" : "LOG IN")
                                .font(.system(size: 14, weight: .black))
                                .tracking(1.0)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.black)
                                .cornerRadius(4)
                        }
                    }
                    .disabled(username.isEmpty || password.isEmpty || isLoading)
                    .opacity(username.isEmpty || password.isEmpty ? 0.6 : 1.0)
                }
                .padding(.horizontal)
                .padding(.top, 40)
                
                Spacer()
                
                // Footer
                Text("COMPETE. REDUCE. WIN.")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAuth() {
        // Basic validation
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        guard username.count >= 3 else {
            errorMessage = "Username must be at least 3 characters"
            showError = true
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }
        
        // Perform authentication
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(username: username, password: password)
                } else {
                    try await authManager.logIn(username: username, password: password)
                }
            } catch {
                await MainActor.run {
                    if let authError = error as? AuthManagerError {
                        errorMessage = authError.localizedDescription
                    } else {
                        // Check if it's a database error
                        if error.localizedDescription.contains("Database error") {
                            errorMessage = "Database not configured. Please run supabase_setup.sql in your Supabase dashboard."
                        } else {
                            errorMessage = "Error: \(error.localizedDescription)"
                        }
                        print("Full error: \(error)")
                    }
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AuthView()
}