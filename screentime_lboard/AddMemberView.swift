//
//  AddMemberView.swift
//  screentime_lboard
//
//  Add members to a group via invites
//

import SwiftUI

struct AddMemberView: View {
    let groupId: String
    let groupName: String
    @ObservedObject var inviteManager: InviteManager
    let isCreator: Bool
    
    @Environment(\.dismiss) var dismiss
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("INVITE TO \(groupName.uppercased())")
                    .font(.system(size: 24, weight: .black))
                    .tracking(1.2)
                    .padding(.top, 20)
                
                if !isCreator {
                    Text("Only group creators can invite new members")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("USERNAME")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter username", text: $username)
                        .font(.system(size: 18, weight: .bold))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .disabled(!isCreator)
                    
                    Text("Usernames are not case-sensitive")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
                
                if !successMessage.isEmpty {
                    Text(successMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text("CANCEL")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.black.opacity(0.08))
                            .cornerRadius(8)
                    }
                    
                    Button(action: sendInvite) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.black)
                                .cornerRadius(8)
                        } else {
                            Text("SEND INVITE")
                                .font(.system(size: 14, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.black)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(username.isEmpty || isLoading || !isCreator)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func sendInvite() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a username"
            return
        }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        Task {
            do {
                try await inviteManager.sendInvite(toUsername: username, forGroup: groupId)
                await MainActor.run {
                    successMessage = "Invite sent to \(username)!"
                    username = ""
                    isLoading = false
                    
                    // Dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AddMemberView(
        groupId: "test",
        groupName: "Family",
        inviteManager: InviteManager(userId: "test"),
        isCreator: true
    )
}