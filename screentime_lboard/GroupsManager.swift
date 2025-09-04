//
//  GroupsManager.swift
//  screentime_lboard
//
//  Manages groups data from Supabase
//

import SwiftUI
import Supabase

@MainActor
class GroupsManager: ObservableObject {
    @Published var groups: [UserGroup] = []
    @Published var selectedGroupId: String?
    @Published var groupMembers: [GroupMember] = []
    @Published var isLoading = false
    @Published var isLoadingMembers = false
    @Published var error: String?
    
    var userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    // Fetch groups where the user is a member
    func fetchUserGroups() async {
        print("fetchUserGroups called with userId: \(userId)")
        
        guard !userId.isEmpty else {
            print("No userId provided, skipping fetch")
            isLoading = false
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // First get all group memberships for the user
            let membershipsResponse = try await supabase
                .from("group_members")
                .select("group_id")
                .eq("user_id", value: userId)
                .execute()
            
            print("Memberships response: \(String(data: membershipsResponse.data, encoding: .utf8) ?? "nil")")
            
            let memberships = try JSONDecoder().decode([GroupMembership].self, from: membershipsResponse.data)
            let groupIds = memberships.map { $0.group_id }
            
            print("Found \(groupIds.count) group memberships")
            
            if groupIds.isEmpty {
                print("No groups found for user")
                groups = []
                isLoading = false
                return
            }
            
            // Then fetch the group details
            let groupsResponse = try await supabase
                .from("groups")
                .select()
                .in("id", values: groupIds)
                .execute()
            
            let fetchedGroups = try JSONDecoder().decode([UserGroup].self, from: groupsResponse.data)
            
            groups = fetchedGroups.sorted { $0.created_at < $1.created_at }
            
            // Select first group if none selected
            if selectedGroupId == nil && !groups.isEmpty {
                selectedGroupId = groups[0].id
            }
            
        } catch {
            self.error = "Failed to fetch groups: \(error.localizedDescription)"
            print("Error fetching groups: \(error)")
        }
        
        isLoading = false
    }
    
    // Create a new group
    func createGroup(name: String) async throws {
        let newGroupResponse = try await supabase
            .from("groups")
            .insert([
                "name": name,
                "created_by": userId
            ])
            .select()
            .single()
            .execute()
        
        let newGroup = try JSONDecoder().decode(UserGroup.self, from: newGroupResponse.data)
        
        // Add creator as a member
        _ = try await supabase
            .from("group_members")
            .insert([
                "group_id": newGroup.id,
                "user_id": userId
            ])
            .execute()
        
        // Refresh groups
        await fetchUserGroups()
    }
    
    // Fetch members of a specific group
    func fetchGroupMembers(for groupId: String) async {
        print("Fetching members for group: \(groupId)")
        isLoadingMembers = true
        groupMembers = []
        
        do {
            // Get all member IDs for the group
            let membersResponse = try await supabase
                .from("group_members")
                .select("user_id, joined_at")
                .eq("group_id", value: groupId)
                .execute()
            
            print("Members response: \(String(data: membersResponse.data, encoding: .utf8) ?? "nil")")
            
            struct MembershipData: Codable {
                let user_id: String
                let joined_at: String
            }
            
            let memberships = try JSONDecoder().decode([MembershipData].self, from: membersResponse.data)
            
            // Fetch user details and screen time for each member
            var members: [GroupMember] = []
            
            for membership in memberships {
                // Get user details
                let userResponse = try await supabase
                    .from("users")
                    .select("id, username")
                    .eq("id", value: membership.user_id)
                    .single()
                    .execute()
                
                struct UserData: Codable {
                    let id: String
                    let username: String
                }
                
                let userData = try JSONDecoder().decode(UserData.self, from: userResponse.data)
                
                // Get today's screen time (if available)
                let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // YYYY-MM-DD format
                let screenTimeResponse = try await supabase
                    .from("screen_time_entries")
                    .select("duration_minutes")
                    .eq("user_id", value: membership.user_id)
                    .eq("date", value: String(today))
                    .execute()
                
                struct ScreenTimeData: Codable {
                    let duration_minutes: Int
                }
                
                var todayMinutes = 0
                if let screenTimeData = try? JSONDecoder().decode([ScreenTimeData].self, from: screenTimeResponse.data),
                   let firstEntry = screenTimeData.first {
                    todayMinutes = firstEntry.duration_minutes
                }
                
                let member = GroupMember(
                    id: userData.id,
                    username: userData.username,
                    joinedAt: membership.joined_at,
                    todayScreenTime: todayMinutes,
                    isCurrentUser: userData.id == userId
                )
                members.append(member)
            }
            
            // Sort by screen time (lowest first)
            groupMembers = members.sorted { $0.todayScreenTime < $1.todayScreenTime }
            
        } catch {
            print("Error fetching group members: \(error)")
            self.error = "Failed to fetch group members"
            groupMembers = []
        }
        
        isLoadingMembers = false
    }
    
    // Add a member to a group (only if user is the creator)
    func addMemberToGroup(groupId: String, username: String) async throws {
        // First check if current user is the creator
        guard let group = groups.first(where: { $0.id == groupId }),
              group.created_by == userId else {
            throw GroupError.notAuthorized
        }
        
        // Find user by username
        let userResponse = try await supabase
            .from("users")
            .select("id")
            .eq("username", value: username)
            .single()
            .execute()
        
        struct UserIdResponse: Codable {
            let id: String
        }
        
        let user = try JSONDecoder().decode(UserIdResponse.self, from: userResponse.data)
        
        // Add member to group
        _ = try await supabase
            .from("group_members")
            .insert([
                "group_id": groupId,
                "user_id": user.id
            ])
            .execute()
    }
}

// Data Models
struct UserGroup: Codable, Identifiable {
    let id: String
    let name: String
    let created_by: String
    let created_at: String
    let updated_at: String
}

struct GroupMembership: Codable {
    let group_id: String
}

struct GroupMember: Identifiable {
    let id: String
    let username: String
    let joinedAt: String
    let todayScreenTime: Int // in minutes
    let isCurrentUser: Bool
    
    var screenTimeFormatted: String {
        let hours = todayScreenTime / 60
        let minutes = todayScreenTime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

enum GroupError: LocalizedError {
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "You are not authorized to perform this action"
        }
    }
}