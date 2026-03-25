// MyBadgesView.swift
import SwiftUI

struct MyBadgesView: View {
    let plants: [Plant]
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    private var badgeManager: EnhancedBadgeManager {
        EnhancedBadgeManager.shared
    }
    
    private var unlockedBadges: [Badge] {
        badgeManager.unlockedBadges(for: plants)
    }
    
    private var lockedBadges: [Badge] {
        badgeManager.allBadges.filter { badge in
            !unlockedBadges.contains(where: { $0.id == badge.id })
        }
    }
    private var activeBadges: [Badge] {
        badgeManager.activeBadges(for: plants)
    }
    
    private var inactiveBadges: [Badge] {
        badgeManager.inactiveBadges(for: plants)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerStats
                
                if !activeBadges.isEmpty {
                    badgeSection(
                        title: "Active Badges",
                        subtitle: "Currently maintained",
                        badges: activeBadges,
                        isActive: true
                    )
                }
                
                if !inactiveBadges.isEmpty {
                    badgeSection(
                        title: "Inactive Badges",
                        subtitle: "Previously earned, no longer active",
                        badges: inactiveBadges,
                        isActive: false
                    )
                }
                
                if !lockedBadges.isEmpty {
                    badgeSection(
                        title: "Locked",
                        subtitle: "Keep working to unlock these",
                        badges: lockedBadges,
                        isActive: false
                    )
                }
            }
            .padding(.vertical)
        }
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("My Badges")
        .navigationBarTitleDisplayMode(.large)
    }
    private var headerStats: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Achievement Progress")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                StatBadge(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    value: activeBadges.count,
                    label: "Active"
                )
                
                StatBadge(
                    icon: "exclamationmark.circle.fill",
                    color: .orange,
                    value: inactiveBadges.count,
                    label: "Inactive"
                )
                
                StatBadge(
                    icon: "lock.fill",
                    color: .gray,
                    value: lockedBadges.count,
                    label: "Locked"
                )
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(unlockedBadges.count) of \(badgeManager.allBadges.count) badges unlocked")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ProgressView(value: Double(unlockedBadges.count), total: Double(badgeManager.allBadges.count))
                    .tint(.green)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Badge Section
    private func badgeSection(title: String, subtitle: String, badges: [Badge], isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(badges) { badge in
                    BadgeCardView(
                        badge: badge,
                        plants: plants,
                        isUnlocked: badge.isUnlocked,
                        isActive: isActive && badge.isUnlocked
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Stat Badge Component
struct StatBadge: View {
    let icon: String
    let color: Color
    let value: Int
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Badge Card View
struct BadgeCardView: View {
    let badge: Badge
    let plants: [Plant]
    let isUnlocked: Bool
    let isActive: Bool
    
    private var progress: Double {
        EnhancedBadgeManager.shared.progress(for: badge, plants: plants)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 80, height: 80)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(iconForegroundColor)
                
                if isUnlocked {
                    VStack {
                        HStack {
                            Spacer()
                            statusBadge
                        }
                        Spacer()
                    }
                    .frame(width: 80, height: 80)
                }
            }
            
            VStack(spacing: 4) {
                Text(badge.name)
                    .font(.headline)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(badge.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if !isUnlocked {
                    VStack(spacing: 4) {
                        ProgressView(value: progress)
                            .tint(.green)
                            .padding(.top, 4)
                        
                        Text("\(Int(progress * 100))% complete")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let date = badge.unlockedDate {
                    Text(date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .opacity(cardOpacity)
    }
    
    // MARK: - Computed Properties
    private var statusBadge: some View {
        Group {
            if isUnlocked && isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Color.green)
                    .clipShape(Circle())
            } else if isUnlocked && !isActive {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Color.orange)
                    .clipShape(Circle())
            }
        }
    }
    
    private var iconBackgroundColor: Color {
        if isUnlocked && isActive {
            return .yellow.opacity(0.2)
        } else if isUnlocked && !isActive {
            return .orange.opacity(0.15)
        } else {
            return .gray.opacity(0.1)
        }
    }
    
    private var iconForegroundColor: Color {
        if isUnlocked && isActive {
            return .yellow
        } else if isUnlocked && !isActive {
            return .orange.opacity(0.7)
        } else {
            return .gray.opacity(0.4)
        }
    }
    
    private var borderColor: Color {
        if isUnlocked && isActive {
            return .yellow.opacity(0.5)
        } else if isUnlocked && !isActive {
            return .orange.opacity(0.3)
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        isUnlocked ? 2 : 0
    }
    
    private var cardOpacity: Double {
        if isUnlocked {
            return isActive ? 1.0 : 0.75
        } else {
            return 0.6
        }
    }
}

