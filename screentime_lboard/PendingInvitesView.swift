//
//  PendingInvitesView.swift
//  screentime_lboard
//
//  View and manage pending group invites
//

import SwiftUI

struct PendingInvitesView: View {
    @ObservedObject var inviteManager: InviteManager
    @ObservedObject var groupsManager: GroupsManager
    @Environment(\.dismiss) var dismiss
    
    @State private var processingInviteId: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("PENDING INVITES")
                        .font(.system(size: 24, weight: .black))
                        .tracking(1.2)
                    
                    Spacer()
                    
                    Button("DONE") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.5)
                }
                .padding()
                
                if inviteManager.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                } else if inviteManager.pendingInvites.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("NO PENDING INVITES")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(inviteManager.pendingInvites) { invite in
                                InviteRow(
                                    invite: invite,
                                    isProcessing: processingInviteId == invite.id,
                                    onAccept: {
                                        acceptInvite(invite)
                                    },
                                    onDecline: {
                                        declineInvite(invite)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func acceptInvite(_ invite: GroupInvite) {
        processingInviteId = invite.id
        
        Task {
            do {
                try await inviteManager.acceptInvite(invite)
                // Refresh groups after accepting
                await groupsManager.fetchUserGroups()
                await MainActor.run {
                    processingInviteId = nil
                }
            } catch {
                await MainActor.run {
                    processingInviteId = nil
                    // Could show error alert here
                    print("Error accepting invite: \(error)")
                }
            }
        }
    }
    
    private func declineInvite(_ invite: GroupInvite) {
        processingInviteId = invite.id
        
        Task {
            do {
                try await inviteManager.declineInvite(invite)
                await MainActor.run {
                    processingInviteId = nil
                }
            } catch {
                await MainActor.run {
                    processingInviteId = nil
                    print("Error declining invite: \(error)")
                }
            }
        }
    }
}

struct InviteRow: View {
    let invite: GroupInvite
    let isProcessing: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invite.groupName)
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("Invited by \(invite.inviterUsername)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: onDecline) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.black.opacity(0.08))
                            .cornerRadius(6)
                    } else {
                        Text("DECLINE")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.08))
                            .cornerRadius(6)
                    }
                }
                .disabled(isProcessing)
                
                Button(action: onAccept) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.black)
                            .cornerRadius(6)
                    } else {
                        Text("ACCEPT")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .cornerRadius(6)
                    }
                }
                .disabled(isProcessing)
            }
        }
        .padding()
        .background(Color.black.opacity(0.03))
        .cornerRadius(8)
    }
}

#Preview {
    PendingInvitesView(
        inviteManager: InviteManager(userId: "test"),
        groupsManager: GroupsManager(userId: "test")
    )
}