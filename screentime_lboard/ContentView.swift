//
//  ContentView.swift
//  screentime_lboard
//
//  Created by Sharan Subramanian on 9/4/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedGroup = "Family"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Screen Time Card
                    VStack(spacing: 12) {
                        Image(systemName: "iphone")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("5h 23m")
                            .font(.system(size: 40, weight: .semibold))
                        
                        Text("Your total screen time today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("-1h from yesterday")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Groups Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Groups")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.caption)
                                    Text("Create Group")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Group Tabs
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                GroupTab(title: "Family", isSelected: selectedGroup == "Family") {
                                    selectedGroup = "Family"
                                }
                                GroupTab(title: "Work Team", isSelected: selectedGroup == "Work Team") {
                                    selectedGroup = "Work Team"
                                }
                                GroupTab(title: "Friends", isSelected: selectedGroup == "Friends") {
                                    selectedGroup = "Friends"
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Leaderboard
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Family Leaderboard")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.caption)
                                    Text("Add Member")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        Text("Lowest screen time wins! 🏆")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        // Leaderboard List
                        VStack(spacing: 8) {
                            LeaderboardRow(rank: 1, name: "Sarah", time: "2h 15m", change: "-45m", 
                                         avatar: "person.crop.circle.fill", isWinner: true,
                                         subtitle: "Today's champion 🎉")
                            
                            LeaderboardRow(rank: 2, name: "Dad", time: "3h 42m", change: "-20m",
                                         avatar: "person.crop.circle.fill", isWinner: false,
                                         subtitle: "Great progress!")
                            
                            LeaderboardRow(rank: 3, name: "Mom", time: "4h 18m", change: "+15m",
                                         avatar: "person.crop.circle.fill", isWinner: false,
                                         subtitle: "Keep it up!")
                            
                            LeaderboardRow(rank: 4, name: "You", time: "5h 23m", change: "+1h 5m",
                                         avatar: "person.crop.circle.fill", isWinner: false,
                                         subtitle: "Room for improvement", isCurrentUser: true)
                            
                            LeaderboardRow(rank: 5, name: "Alex", time: "7h 45m", change: "+2h 30m",
                                         avatar: "person.crop.circle.fill", isWinner: false,
                                         subtitle: "Try reducing usage")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Bottom Stats
                    HStack(spacing: 16) {
                        VStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Text("3.2h")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Avg Daily")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        VStack(spacing: 6) {
                            Image(systemName: "trophy.fill")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Text("12")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Days Won")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Screen Time")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationBarSubtitle("Leaderboard")
        }
    }
}

struct GroupTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(20)
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
                    .fill(isCurrentUser ? Color.blue : Color(.systemGray5))
                    .frame(width: 28, height: 28)
                
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isCurrentUser ? .white : .primary)
            }
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 44, height: 44)
                
                if isWinner {
                    Image(systemName: "crown.fill")
                        .font(.callout)
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: avatar)
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            
            // Name and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time and change
            VStack(alignment: .trailing, spacing: 2) {
                Text(time)
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text(change)
                    .font(.caption)
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
