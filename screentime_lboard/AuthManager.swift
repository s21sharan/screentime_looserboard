//
//  AuthManager.swift
//  screentime_lboard
//
//  Created by Sharan Subramanian on 9/4/25.
//

import SwiftUI
import Supabase
import CryptoKit

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    init() {
        // Check if we have a saved user session
        Task {
            await checkSavedSession()
        }
    }
    
    private func checkSavedSession() async {
        // Check UserDefaults for saved user
        if let userId = UserDefaults.standard.string(forKey: "userId"),
           let username = UserDefaults.standard.string(forKey: "username") {
            await MainActor.run {
                self.currentUser = User(id: userId, username: username)
                self.isAuthenticated = true
            }
        }
    }
    
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func signUp(username: String, password: String) async throws {
        // Convert username to lowercase for case-insensitive handling
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordHash = hashPassword(password)
        
        do {
            // Check if username already exists
            let existingUserResponse = try await supabase
                .from("users")
                .select()
                .eq("username", value: normalizedUsername)
                .execute()
            
            print("Existing user check - Count: \(existingUserResponse.count)")
            print("Existing user data: \(String(data: existingUserResponse.data, encoding: .utf8) ?? "nil")")
            
            // Check if we got any results
            do {
                let users = try JSONDecoder().decode([UserData].self, from: existingUserResponse.data)
                if !users.isEmpty {
                    throw AuthManagerError.supabaseError("Username already exists")
                }
            } catch {
                // If decode fails, it means no users found (empty array can't decode)
                print("No existing users found, proceeding with signup")
            }
            
            // Create new user
            let newUser = try await supabase
                .from("users")
                .insert([
                    "username": normalizedUsername,
                    "password_hash": passwordHash
                ])
                .select()
                .single()
                .execute()
            
            let userData = try JSONDecoder().decode(UserData.self, from: newUser.data)
            
            // Save to UserDefaults
            UserDefaults.standard.set(userData.id, forKey: "userId")
            UserDefaults.standard.set(userData.username, forKey: "username")
            
            await MainActor.run {
                self.currentUser = User(id: userData.id, username: userData.username)
                self.isAuthenticated = true
            }
            
        } catch {
            print("SignUp error details: \(error)")
            throw AuthManagerError.supabaseError(error.localizedDescription)
        }
    }
    
    func logIn(username: String, password: String) async throws {
        // Convert username to lowercase for case-insensitive handling
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordHash = hashPassword(password)
        
        do {
            // Find user with matching username and password
            let result = try await supabase
                .from("users")
                .select()
                .eq("username", value: normalizedUsername)
                .eq("password_hash", value: passwordHash)
                .single()
                .execute()
            
            let userData = try JSONDecoder().decode(UserData.self, from: result.data)
            
            // Save to UserDefaults
            UserDefaults.standard.set(userData.id, forKey: "userId")
            UserDefaults.standard.set(userData.username, forKey: "username")
            
            await MainActor.run {
                self.currentUser = User(id: userData.id, username: userData.username)
                self.isAuthenticated = true
            }
            
        } catch {
            // If no user found or error occurred
            throw AuthManagerError.invalidCredentials
        }
    }
    
    func logOut() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "username")
        
        // Update state
        self.currentUser = nil
        self.isAuthenticated = false
    }
}

// Data model for decoding user from database
struct UserData: Codable {
    let id: String
    let username: String
    let password_hash: String
    let created_at: String
    let updated_at: String
}

struct User {
    let id: String
    let username: String
}

enum AuthManagerError: LocalizedError {
    case invalidCredentials
    case supabaseError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password"
        case .supabaseError(let message):
            return message
        case .unknownError(let message):
            return "An error occurred: \(message)"
        }
    }
}