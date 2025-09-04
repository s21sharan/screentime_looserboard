//
//  ContentView.swift
//  screentime_lboard
//
//  Created by Sharan Subramanian on 9/4/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var groupsManager = GroupsManager(userId: "")
    @StateObject private var inviteManager = InviteManager(userId: "")
    @State private var showCreateGroup = false
    @State private var showInvites = false
    @State private var showAddMember = false
    @State private var newGroupName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Groups Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("GROUPS")
                                .font(.system(size: 16, weight: .black, design: .default))
                                .tracking(1.5)
                            
                            Spacer()
                            
                            Button(action: { showCreateGroup = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                    Text("CREATE")
                                        .font(.system(size: 12, weight: .bold))
                                        .tracking(0.5)
                                }
                                .foregroundColor(.black)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Group Tabs
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                if groupsManager.isLoading {
                                    ProgressView()
                                        .padding(.horizontal)
                                } else if groupsManager.groups.isEmpty {
                                    Text("No groups yet. Create one!")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                } else {
                                    ForEach(groupsManager.groups) { group in
                                        GroupTab(
                                            title: group.name,
                                            isSelected: groupsManager.selectedGroupId == group.id
                                        ) {
                                            groupsManager.selectedGroupId = group.id
                                            Task {
                                                await groupsManager.fetchGroupMembers(for: group.id)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 12)
                    
                    // Leaderboard
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text((groupsManager.groups.first(where: { $0.id == groupsManager.selectedGroupId })?.name ?? "GROUP").uppercased() + " RANKINGS")
                                .font(.system(size: 20, weight: .black))
                                .tracking(1.2)
                            
                            Spacer()
                            
                            Button(action: { showAddMember = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 14))
                                    Text("ADD")
                                        .font(.system(size: 12, weight: .bold))
                                        .tracking(0.5)
                                }
                                .foregroundColor(.black)
                            }
                            .disabled(groupsManager.selectedGroupId == nil)
                        }
                        .padding(.horizontal)
                        
                        Text("LOWEST SCREEN TIME WINS")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.8)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        // Leaderboard List
                        if groupsManager.isLoadingMembers {
                            ProgressView("Loading members...")
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else if groupsManager.groupMembers.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.3")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("No members yet")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                if let selectedGroup = groupsManager.groups.first(where: { $0.id == groupsManager.selectedGroupId }),
                                   selectedGroup.created_by == authManager.currentUser?.id {
                                    Button(action: { showAddMember = true }) {
                                        Text("INVITE MEMBERS")
                                            .font(.system(size: 12, weight: .bold))
                                            .tracking(0.5)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.black)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(Array(groupsManager.groupMembers.enumerated()), id: \.element.id) { index, member in
                                    LeaderboardRow(
                                        rank: index + 1,
                                        name: member.isCurrentUser ? "You" : member.username,
                                        time: member.screenTimeFormatted,
                                        change: "", // TODO: Add change calculation
                                        avatar: "person.crop.circle.fill",
                                        isWinner: index == 0,
                                        subtitle: getSubtitle(for: index, isCurrentUser: member.isCurrentUser),
                                        isCurrentUser: member.isCurrentUser
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Bottom Stats
                    HStack(spacing: 16) {
                        VStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.black)
                            Text("3.2h")
                                .font(.system(size: 24, weight: .black))
                            Text("AVG DAILY")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                        
                        VStack(spacing: 6) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.black)
                            Text("12")
                                .font(.system(size: 24, weight: .black))
                            Text("DAYS WON")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("ScreensAway")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                print("ContentView appeared. Current user: \(authManager.currentUser?.username ?? "nil")")
                if let userId = authManager.currentUser?.id {
                    print("User ID found: \(userId)")
                    // Update managers with the actual user ID
                    Task {
                        groupsManager.userId = userId
                        inviteManager.userId = userId
                        
                        await groupsManager.fetchUserGroups()
                        await inviteManager.fetchPendingInvites()
                        
                        // Fetch members for the initially selected group
                        if let selectedId = groupsManager.selectedGroupId {
                            await groupsManager.fetchGroupMembers(for: selectedId)
                        }
                    }
                } else {
                    print("No user ID found!")
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView(groupsManager: groupsManager)
            }
            .sheet(isPresented: $showAddMember) {
                if let selectedGroupId = groupsManager.selectedGroupId,
                   let selectedGroup = groupsManager.groups.first(where: { $0.id == selectedGroupId }) {
                    AddMemberView(
                        groupId: selectedGroupId,
                        groupName: selectedGroup.name,
                        inviteManager: inviteManager,
                        isCreator: selectedGroup.created_by == authManager.currentUser?.id
                    )
                }
            }
            .sheet(isPresented: $showInvites) {
                PendingInvitesView(
                    inviteManager: inviteManager,
                    groupsManager: groupsManager
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Invites notification
                        Button(action: { showInvites = true }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.black)
                                
                                if inviteManager.pendingCount > 0 {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Text("\(inviteManager.pendingCount)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                        
                        // Settings menu
                        Menu {
                            if let user = authManager.currentUser {
                                Section {
                                    Text("Signed in as \(user.username)")
                                        .font(.caption)
                                }
                            }
                            
                            Button(action: { authManager.logOut() }) {
                                Label("LOG OUT", systemImage: "arrow.right.square")
                            }
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.black)
                        }
                    }
                }
            }
        }
    }
    
    private func getSubtitle(for rank: Int, isCurrentUser: Bool) -> String {
        switch rank {
        case 0:
            return "Today's champion 🎉"
        case 1:
            return "Great job!"
        case 2:
            return "Keep it up!"
        default:
            if isCurrentUser {
                return "You can do better!"
            } else {
                return "Making progress"
            }
        }
    }
}

struct GroupTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: isSelected ? .black : .bold))
                .tracking(1.0)
                .foregroundColor(isSelected ? .white : .black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.black : Color.black.opacity(0.08))
                .cornerRadius(4)
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let time: String
    let change: String
    let avatar: String
    let isWinner: Bool
    let subtitle: String
    var isCurrentUser: Bool = false
    
    var changeColor: Color {
        change.hasPrefix("+") ? .red : .green
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                Circle()
                    .fill(isCurrentUser ? Color.black : Color(.systemGray5))
                    .frame(width: 28, height: 28)
                
                Text("\(rank)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(isCurrentUser ? .white : .black)
            }
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 44, height: 44)
                
                if isWinner {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: avatar)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            
            // Name and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .bold))
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time and change
            VStack(alignment: .trailing, spacing: 2) {
                Text(time)
                    .font(.system(size: 18, weight: .black))
                
                Text(change)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(changeColor)
            }
        }
        .padding(.vertical, 6)
    }
}

// Extension for navigation subtitle
extension View {
    func navigationBarSubtitle(_ subtitle: String) -> some View {
        self
    }
}

#Preview {
    ContentView()
}
