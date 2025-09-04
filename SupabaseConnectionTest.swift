//
//  SupabaseConnectionTest.swift
//  screentime_lboard
//
//  Test file to verify Supabase connection
//

import SwiftUI

struct SupabaseConnectionTest: View {
    @State private var testResults: [String] = []
    @State private var isLoading = false
    @State private var testEmail = "testuser\(Int.random(in: 1000...9999))@screensaway.app"
    @State private var testPassword = "testpass123"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Supabase Connection Test")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(testResults, id: \.self) { result in
                        Text(result)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 400)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            HStack(spacing: 20) {
                Button("Run Connection Test") {
                    Task {
                        await runConnectionTest()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Clear Results") {
                    testResults.removeAll()
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func addResult(_ message: String) {
        testResults.append("[\(Date().formatted(.dateTime.hour().minute().second()))] \(message)")
    }
    
    private func runConnectionTest() async {
        isLoading = true
        testResults.removeAll()
        
        addResult("Starting Supabase connection test...")
        addResult("Test email: \(testEmail)")
        
        // Test 1: Check if AuthManager initializes
        addResult("\n--- Test 1: AuthManager Initialization ---")
        let authManager = AuthManager()
        addResult("✅ AuthManager initialized successfully")
        
        // Test 2: Try to sign up a test user
        addResult("\n--- Test 2: Sign Up Test ---")
        do {
            try await authManager.signUp(
                username: testEmail.components(separatedBy: "@").first ?? "testuser",
                password: testPassword
            )
            addResult("✅ Sign up successful!")
            addResult("Session: \(authManager.session != nil ? "Active" : "None")")
            addResult("User: \(authManager.currentUser?.username ?? "None")")
        } catch {
            addResult("❌ Sign up failed: \(error.localizedDescription)")
            addResult("Error details: \(error)")
        }
        
        // Test 3: Try to log out
        if authManager.isAuthenticated {
            addResult("\n--- Test 3: Log Out Test ---")
            authManager.logOut()
            // Wait a moment for logout to complete
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            addResult("✅ Logged out successfully")
            addResult("Is authenticated: \(authManager.isAuthenticated)")
        }
        
        // Test 4: Try to log in with the same credentials
        addResult("\n--- Test 4: Log In Test ---")
        do {
            try await authManager.logIn(
                username: testEmail.components(separatedBy: "@").first ?? "testuser",
                password: testPassword
            )
            addResult("✅ Log in successful!")
            addResult("Session: \(authManager.session != nil ? "Active" : "None")")
            addResult("User: \(authManager.currentUser?.username ?? "None")")
        } catch {
            addResult("❌ Log in failed: \(error.localizedDescription)")
        }
        
        // Test 5: Check current session
        addResult("\n--- Test 5: Session Check ---")
        addResult("Current auth state:")
        addResult("- Is authenticated: \(authManager.isAuthenticated)")
        addResult("- Session exists: \(authManager.session != nil)")
        addResult("- Current user: \(authManager.currentUser?.username ?? "None")")
        
        addResult("\n✅ Connection test completed!")
        
        isLoading = false
    }
}

#Preview {
    SupabaseConnectionTest()
}