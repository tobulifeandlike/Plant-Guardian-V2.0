// BadgeSystem.swift 
import Foundation
import SwiftUI

// MARK: - Badge Unlock Notification
struct BadgeUnlockNotification: Identifiable {
    let id = UUID()
    let badge: Badge
    let unlockedAt: Date
}

// MARK: - Enhanced Badge Manager
@MainActor
class EnhancedBadgeManager: ObservableObject {
    static let shared = EnhancedBadgeManager()
    
    // MARK: - Published State
    @Published var showUnlockPopup = false
    @Published var currentUnlockedBadge: Badge?
    @Published var recentUnlocks: [BadgeUnlockNotification] = []
    
    @Published var badgeQueue: [Badge] = []
    @Published var isShowingBadge = false
    
    // MARK: - Persistent Storage
    private let userDefaults = UserDefaults.standard
    private let unlockedBadgesKey = "unlockedBadges"
    private var unlockedBadgeIDs: Set<String> = []
    
    private init() {
        loadUnlockedBadges()
    }
    
    // MARK: - Badge Definitions
    let allBadges: [Badge] = [
        Badge(
            id: "first_plant",
            name: "First Sprout",
            description: "Planted your very first companion",
            icon: "leaf.fill",
            requirement: .firstPlant
        ),
        Badge(
            id: "five_plants",
            name: "Growing Garden",
            description: "Built a collection of 5 plants",
            icon: "tree.fill",
            requirement: .fivePlants
        ),
        Badge(
            id: "ten_plants",
            name: "Plant Collector",
            description: "Nurtured 10 beautiful plants",
            icon: "trophy.fill",
            requirement: .tenPlants
        ),
        Badge(
            id: "all_healthy",
            name: "Health Guardian",
            description: "All your plants are thriving",
            icon: "heart.fill",
            requirement: .allHealthy
        ),
        Badge(
            id: "week_streak",
            name: "Consistent Caretaker",
            description: "7-day watering streak",
            icon: "calendar.badge.checkmark",
            requirement: .weekStreak
        ),
        Badge(
            id: "diversity_3",
            name: "Variety Lover",
            description: "Collected 3 different plant species",
            icon: "star.fill",
            requirement: .diversity(3)
        ),
        Badge(
            id: "diversity_5",
            name: "Botanical Enthusiast",
            description: "Collected 5 different plant species",
            icon: "star.circle.fill",
            requirement: .diversity(5)
        ),
        Badge(
            id: "green_thumb",
            name: "Green Thumb Master",
            description: "Achieved 100% health on all plants",
            icon: "sparkles",
            requirement: .greenThumb
        )
    ]
    
    // MARK: - NEW: Active/Inactive Badge Helpers
    func isActive(badge: Badge, plants: [Plant]) -> Bool {
        guard badge.isUnlocked else { return false }
        return checkRequirement(badge.requirement, plants: plants)
    }
    func activeBadges(for plants: [Plant]) -> [Badge] {
        unlockedBadges(for: plants).filter { badge in
            checkRequirement(badge.requirement, plants: plants)
        }
    }
    func inactiveBadges(for plants: [Plant]) -> [Badge] {
        unlockedBadges(for: plants).filter { badge in
            !checkRequirement(badge.requirement, plants: plants)
        }
    }
    // MARK: - Core Logic: Check & Unlock
    func checkAndUnlockBadges(for plants: [Plant]) -> [Badge] {
        var newlyUnlocked: [Badge] = []
        for badge in allBadges {
            if unlockedBadgeIDs.contains(badge.id) {
                continue
            }
            if checkRequirement(badge.requirement, plants: plants) {
                unlockedBadgeIDs.insert(badge.id)
                saveUnlockedBadges()
                
                let notification = BadgeUnlockNotification(
                    badge: badge,
                    unlockedAt: Date()
                )
                recentUnlocks.insert(notification, at: 0)
                if recentUnlocks.count > 10 {
                    recentUnlocks.removeLast()
                }
                newlyUnlocked.append(badge)
                print("Badge unlocked: \(badge.name)")
            }
        }
        
        if !newlyUnlocked.isEmpty {
            badgeQueue.append(contentsOf: newlyUnlocked)
            announceMultipleBadges(newlyUnlocked)
            showNextBadgeInQueue()
        }
        
        return newlyUnlocked
    }
    
    // MARK: - Queue Management
    private func showNextBadgeInQueue() {
        guard !isShowingBadge, !badgeQueue.isEmpty else { return }
        
        isShowingBadge = true
        currentUnlockedBadge = badgeQueue.removeFirst()
        showUnlockPopup = true
        
        VoiceNotificationManager.shared.playSoundEffect(.unlockBadge)
        
        print("Showing Badge: \(currentUnlockedBadge?.name ?? "Unknown") (Remaining: \(badgeQueue.count))")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.showUnlockPopup = false
            self?.isShowingBadge = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showNextBadgeInQueue()
            }
        }
    }
    
    func closeCurrentBadge() {
        showUnlockPopup = false
        isShowingBadge = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showNextBadgeInQueue()
        }
    }
    
    // MARK: - Voice Announcements
    private func announceMultipleBadges(_ badges: [Badge]) {
        let count = badges.count
        
        if count == 1 {
            VoiceNotificationManager.shared.celebrateBadgeUnlock(badgeName: badges[0].name)
        } else if count == 2 {
            let message = "Congratulations! You unlocked 2 badges: \(badges[0].name) and \(badges[1].name)!"
            VoiceNotificationManager.shared.announceImmediate(message)
        } else {
            let message = "Amazing! You unlocked \(count) badges at once! Check them out!"
            VoiceNotificationManager.shared.announceImmediate(message)
        }
    }
    
    // MARK: - Requirement Check
    func checkRequirement(_ requirement: BadgeRequirement, plants: [Plant]) -> Bool {
        switch requirement {
        case .firstPlant:
            return plants.count >= 1
            
        case .fivePlants:
            return plants.count >= 5
            
        case .tenPlants:
            return plants.count >= 10
            
        case .allHealthy:
            return plants.count >= 2 && plants.allSatisfy { $0.healthScore > 70 }
            
        case .diversity(let count):
            let uniqueTypes = Set(plants.map { $0.type })
            return uniqueTypes.count >= count
            
        case .greenThumb:
            return plants.count >= 3 && plants.allSatisfy { $0.healthScore >= 100 }
            
        case .weekStreak, .monthStreak, .healthMaster, .earlyBird:
            return false
        }
    }
    
    // MARK: - Get Unlocked Badges
    func unlockedBadges(for plants: [Plant]) -> [Badge] {
        allBadges.filter { unlockedBadgeIDs.contains($0.id) }
    }
    
    func isUnlocked(_ badgeID: String) -> Bool {
        unlockedBadgeIDs.contains(badgeID)
    }
    
    // MARK: - Progress Tracking
    func progress(for badge: Badge, plants: [Plant]) -> Double {
        switch badge.requirement {
        case .firstPlant:
            return plants.isEmpty ? 0 : 1
        case .fivePlants:
            return min(Double(plants.count) / 5.0, 1.0)
        case .tenPlants:
            return min(Double(plants.count) / 10.0, 1.0)
        case .diversity(let target):
            let unique = Set(plants.map { $0.type }).count
            return min(Double(unique) / Double(target), 1.0)
        case .allHealthy:
            guard plants.count >= 2 else { return 0 }
            let healthyCount = plants.filter { $0.healthScore > 70 }.count
            return Double(healthyCount) / Double(plants.count)
        case .greenThumb:
            guard plants.count >= 3 else { return 0 }
            let perfectCount = plants.filter { $0.healthScore >= 100 }.count
            return Double(perfectCount) / Double(plants.count)
        default:
            return 0
        }
    }
    
    // MARK: - Persistence
    private func loadUnlockedBadges() {
        if let data = userDefaults.data(forKey: unlockedBadgesKey),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlockedBadgeIDs = ids
            print("Loaded \(ids.count) unlocked badges from storage")
        } else {
        }
    }
    
    private func saveUnlockedBadges() {
        if let data = try? JSONEncoder().encode(unlockedBadgeIDs) {
            userDefaults.set(data, forKey: unlockedBadgesKey)
            print("Saved \(unlockedBadgeIDs.count) unlocked badges")
        }
    }
    
    func resetAllBadges() {
        unlockedBadgeIDs.removeAll()
        saveUnlockedBadges()
        recentUnlocks.removeAll()
        badgeQueue.removeAll()
        print("All badges reset")
    }
}

// MARK: - Badge Unlock Popup View
struct BadgeUnlockPopup: View {
    let badge: Badge
    @Binding var isPresented: Bool
    
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = -180
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow, .orange],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .yellow.opacity(0.6), radius: 20)
                    
                    Image(systemName: badge.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                
                VStack(spacing: 8) {
                    Text("Badge Unlocked!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Text(badge.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(badge.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(opacity)
                
                Button(isLastBadge ? "Awesome!" : "Continue") {
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(isLastBadge ? Color.green : Color.blue)
                .clipShape(Capsule())
                .opacity(opacity)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                rotation = 0
            }
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1.0
            }
        }
    }
    
    private var isLastBadge: Bool {
        EnhancedBadgeManager.shared.badgeQueue.isEmpty
    }
    
    private func dismiss() {
        withAnimation {
            opacity = 0
            scale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            EnhancedBadgeManager.shared.closeCurrentBadge()
        }
    }
}

