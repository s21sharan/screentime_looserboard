//
//  InviteManager.swift
//  screentime_lboard
//
//  Manages group invitations
//

import SwiftUI
import Supabase

@MainActor
class InviteManager: ObservableObject {
    @Published var pendingInvites: [GroupInvite] = []
    @Published var pendingCount = 0
    @Published var isLoading = false
    @Published var error: String?
    
    var userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    // Fetch pending invites for the current user
    func fetchPendingInvites() async {
        guard !userId.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        do {
            // Get invites where user is the invitee and status is pending
            // For now, let's fetch invites without joins to avoid complexity
            let response = try await supabase
                .from("group_invites")
                .select()
                .eq("invitee_id", value: userId)
                .eq("status", value: "pending")
                .execute()
            
            print("Pending invites response: \(String(data: response.data, encoding: .utf8) ?? "nil")")
            
            struct SimpleInviteResponse: Codable {
                let id: String
                let group_id: String
                let inviter_id: String
                let invitee_id: String
                let status: String
                let created_at: String
            }
            
            let inviteResponses = try JSONDecoder().decode([SimpleInviteResponse].self, from: response.data)
            
            // Now fetch group names and inviter names separately
            var invites: [GroupInvite] = []
            
            for inviteResponse in inviteResponses {
                // Fetch group name
                let groupResponse = try await supabase
                    .from("groups")
                    .select("name")
                    .eq("id", value: inviteResponse.group_id)
                    .single()
                    .execute()
                
                struct GroupName: Codable {
                    let name: String
                }
                let groupData = try JSONDecoder().decode(GroupName.self, from: groupResponse.data)
                
                // Fetch inviter username
                let inviterResponse = try await supabase
                    .from("users")
                    .select("username")
                    .eq("id", value: inviteResponse.inviter_id)
                    .single()
                    .execute()
                
                struct Username: Codable {
                    let username: String
                }
                let inviterData = try JSONDecoder().decode(Username.self, from: inviterResponse.data)
                
                let invite = GroupInvite(
                    id: inviteResponse.id,
                    groupId: inviteResponse.group_id,
                    groupName: groupData.name,
                    inviterId: inviteResponse.inviter_id,
                    inviterUsername: inviterData.username,
                    inviteeId: inviteResponse.invitee_id,
                    status: inviteResponse.status,
                    createdAt: inviteResponse.created_at
                )
                invites.append(invite)
            }
            
            pendingInvites = invites
            
            pendingCount = pendingInvites.count
            
        } catch {
            print("Error fetching invites: \(error)")
            self.error = "Failed to fetch invites"
            pendingInvites = []
            pendingCount = 0
        }
        
        isLoading = false
    }
    
    // Send an invite to a user
    func sendInvite(toUsername username: String, forGroup groupId: String) async throws {
        // Convert username to lowercase for case-insensitive handling
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // First find the user by username
        let userResponse = try await supabase
            .from("users")
            .select("id")
            .eq("username", value: normalizedUsername)
            .execute()
        
        struct UserIdResponse: Codable {
            let id: String
        }
        
        // Try to decode as array first
        let users = try JSONDecoder().decode([UserIdResponse].self, from: userResponse.data)
        
        guard !users.isEmpty else {
            throw InviteError.userNotFound
        }
        
        let user = users[0]
        
        // Check if invite already exists
        let existingInviteResponse = try await supabase
            .from("group_invites")
            .select("id")
            .eq("group_id", value: groupId)
            .eq("invitee_id", value: user.id)
            .execute()
        
        // Check if response contains data
        do {
            let existingInvites = try JSONDecoder().decode([UserIdResponse].self, from: existingInviteResponse.data)
            if !existingInvites.isEmpty {
                throw InviteError.inviteAlreadyExists
            }
        } catch DecodingError.typeMismatch {
            // Empty array case - no existing invites
        }
        
        // Check if user is already a member
        let existingMemberResponse = try await supabase
            .from("group_members")
            .select("id")
            .eq("group_id", value: groupId)
            .eq("user_id", value: user.id)
            .execute()
        
        // Check if response contains data
        do {
            let existingMembers = try JSONDecoder().decode([UserIdResponse].self, from: existingMemberResponse.data)
            if !existingMembers.isEmpty {
                throw InviteError.userAlreadyMember
            }
        } catch DecodingError.typeMismatch {
            // Empty array case - no existing members
        }
        
        // Create the invite
        _ = try await supabase
            .from("group_invites")
            .insert([
                "group_id": groupId,
                "inviter_id": userId,
                "invitee_id": user.id
            ])
            .execute()
    }
    
    // Accept an invite
    func acceptInvite(_ invite: GroupInvite) async throws {
        // Call the stored function to accept invite and add to group
        _ = try await supabase
            .rpc("accept_group_invite", params: ["invite_id": invite.id])
            .execute()
        
        // Refresh invites
        await fetchPendingInvites()
    }
    
    // Decline an invite
    func declineInvite(_ invite: GroupInvite) async throws {
        _ = try await supabase
            .from("group_invites")
            .update(["status": "declined"])
            .eq("id", value: invite.id)
            .execute()
        
        // Refresh invites
        await fetchPendingInvites()
    }
}

// Data Models
struct GroupInvite: Identifiable {
    let id: String
    let groupId: String
    let groupName: String
    let inviterId: String
    let inviterUsername: String
    let inviteeId: String
    let status: String
    let createdAt: String
}


enum InviteError: LocalizedError {
    case userNotFound
    case inviteAlreadyExists
    case userAlreadyMember
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .inviteAlreadyExists:
            return "An invite has already been sent to this user"
        case .userAlreadyMember:
            return "User is already a member of this group"
        case .notAuthorized:
            return "You are not authorized to invite users to this group"
        }
    }
}