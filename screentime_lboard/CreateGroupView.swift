//
//  CreateGroupView.swift
//  screentime_lboard
//
//  Create a new group
//

import SwiftUI

struct CreateGroupView: View {
    @ObservedObject var groupsManager: GroupsManager
    @Environment(\.dismiss) var dismiss
    
    @State private var groupName = ""
    @State private var isCreating = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("CREATE NEW GROUP")
                    .font(.system(size: 24, weight: .black))
                    .tracking(1.2)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("GROUP NAME")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter group name", text: $groupName)
                        .font(.system(size: 18, weight: .bold))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
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
                    
                    Button(action: createGroup) {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.black)
                                .cornerRadius(8)
                        } else {
                            Text("CREATE GROUP")
                                .font(.system(size: 14, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.black)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(groupName.isEmpty || isCreating)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func createGroup() {
        guard !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a group name"
            return
        }
        
        isCreating = true
        errorMessage = ""
        
        Task {
            do {
                try await groupsManager.createGroup(name: groupName)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create group: \(error.localizedDescription)"
                    isCreating = false
                }
            }
        }
    }
}

#Preview {
    CreateGroupView(groupsManager: GroupsManager(userId: "test"))
}