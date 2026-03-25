// ContentView.swift - Main Screen Layout with Demo Mode
import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Plant.nextWateringDate) private var plants: [Plant]
    
    @State private var showingAddSheet = false
    @State private var navigateToPlantList = false
    @State private var navigateToBadges = false
    @State private var navigateToKnowYourApp = false 
    @State private var navigateToMoreFunctions = false 
    @State private var showingTasksDetail = false
    @State private var showingTipsDetail = false
    @State private var hasGreeted = false 
    @State private var useFahrenheit = false 
    @State private var showingOnboarding = false
    
    // NEW: Demo Mode control
    @AppStorage("isDemoMode") private var isDemoMode = true  // Default ON
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Access to modelContext for plant deletion
    @Environment(\.modelContext) private var modelContext
    
    // Managers
    @StateObject private var voiceManager = VoiceNotificationManager.shared
    @StateObject private var weatherManager = MockWeatherManager.shared 
    @StateObject private var badgeManager = EnhancedBadgeManager.shared  
    // Plant Statistics
    private var statistics: PlantStatistics {
        calculateStatistics()
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // MARK: - Layer 1: Linear Gradient
                backgroundGradient
                
                // MARK: - Layer 2: 3D Garden
                sceneKitGardenBackground
                
                // MARK: - Layer 3: ScrollView over the Garden
                transparentScrollContent
                
                // MARK: - Layer 4: Top Navigation Bar
                topNavigationBar
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(edges: .top)
            .sheet(isPresented: $showingAddSheet) {
                AddPlantView()
            }
            .sheet(isPresented: $showingTasksDetail) {
                TodayTasksDetailView(plants: plants)
            }
            .sheet(isPresented: $showingTipsDetail) {
                CareTipsDetailView()
            }
            .navigationDestination(isPresented: $navigateToPlantList) {
                MyPlantsView_Enhanced()  
            }
            .navigationDestination(isPresented: $navigateToBadges) {
                MyBadgesView(plants: plants)
            }
            .navigationDestination(isPresented: $navigateToKnowYourApp) { 
                KnowYourAppView()
            }
            .navigationDestination(isPresented: $navigateToMoreFunctions) {
                MoreFunctionsView() 
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                hasCompletedOnboarding = true
            } content: {
                OnboardingView(isPresented: $showingOnboarding)
            }
        }
        .onAppear {
            // Only auto-show onboarding if demo mode is ON and not completed
            if isDemoMode && !hasCompletedOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingOnboarding = true
                }
            }
        }
        .onChange(of: plants.count) { oldValue, newValue in
            let _ = badgeManager.checkAndUnlockBadges(for: plants)
        }
        .onChange(of: plants.map { $0.healthScore }) { oldValue, newValue in
            let _ = badgeManager.checkAndUnlockBadges(for: plants)
        }
        // Badge unlock popup overlay
        .overlay {
            if badgeManager.showUnlockPopup, let badge = badgeManager.currentUnlockedBadge {
                BadgeUnlockPopup(badge: badge, isPresented: $badgeManager.showUnlockPopup)
            }
        }
    }
    
    // MARK: - Layer 1: Linear Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.green.opacity(0.2),
                Color.blue.opacity(0.15),
                Color.mint.opacity(0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Layer 2: SceneKit 3D Garden 
    private var sceneKitGardenBackground: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 100)
            
            SceneKitGardenView(plants: plants)
                .frame(height: 200)
                .padding(.horizontal, 16)
            
            Spacer()
        }
    }
    
    // MARK: - Layer 3: Transparent Scroll View
    private var transparentScrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Color.clear.frame(height: 108)
                
                // NEW: Top Right Controls (Temperature + Demo Mode)
                HStack {
                    topRightControls
                    Spacer()
                }
                .padding(.horizontal)
                
                Color.clear.frame(height: 200)
                
                // Content Cards
                VStack(spacing: 20) {
                    // Today's Tasks
                    Button {
                        showingTasksDetail = true
                    } label: {
                        todayTasksCard
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    // Voice Reminder
                    voiceReminderSection
                        .padding(.horizontal)
                    
                    // My Plants
                    Button {
                        navigateToPlantList = true
                    } label: {
                        navigationRow(
                            icon: "laurel.leading",
                            iconColor: .green,
                            title: "My Plants",
                            subtitle: "\(plants.count) plant\(plants.count == 1 ? "" : "s") in your collection"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    Button {
                        navigateToKnowYourApp = true
                    } label: {
                        navigationRow(
                            icon: "questionmark.circle.fill",
                            iconColor: .blue,
                            title: "Know Your App",
                            subtitle: "Learn how to use Plant Guardian"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    // My Badges
                    Button {
                        navigateToBadges = true
                    } label: {
                        navigationRow(
                            icon: "star.circle.fill",
                            iconColor: .yellow,
                            title: "My Badges",
                            subtitle: badgeSubtitle
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    // More Functions
                    Button {
                        navigateToMoreFunctions = true
                    } label: {
                        navigationRow(
                            icon: "ellipsis.circle.fill",
                            iconColor: .orange,
                            title: "More Functions",
                            subtitle: "More functions coming in the future!"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    // Care Tips
                    Button {
                        showingTipsDetail = true
                    } label: {
                        careTipsCard
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    Color.clear.frame(height: 100)
                }
            }
        }
    }
    
    // MARK: - Layer 4: Top Navigation Bar
    private var topNavigationBar: some View {
        HStack {
            Text("My Garden")
                .foregroundStyle(.white)
                .font(.system(size: 24))
                .fontWeight(.heavy)
                .fontDesign(.rounded)
            
            Spacer()
            
            Button {
                showingAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal)
        .padding(.top, 60)
        .padding(.bottom, 8)
        .background(Color(red: 0.565, green: 0.833, blue: 0.728))
    }
    
    // MARK: - NEW: Top Right Controls (Temperature + Demo Mode)
    // Function: Combines temperature toggle and demo mode button in same horizontal layout
    // Complexity: O(1) rendering, O(n) when demo mode triggers plant deletion
    private var topRightControls: some View {
        HStack(spacing: 12) {
            // Temperature button (existing)
            Button { 
                useFahrenheit.toggle() 
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 14))
                        Text(weatherManager.formattedTemperature(useFahrenheit: useFahrenheit))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "humidity")
                            .font(.system(size: 14))
                        Text(weatherManager.formattedHumidity())
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Spacer()
            // NEW: Demo Mode Toggle Button
            // Function: Toggles demo mode, clears data when enabled, shows onboarding
            // Correlation: Responds to judge's need to reset app to pristine state
            Button {
                toggleDemoMode()
            } label: {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Demo Mode")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    Text(isDemoMode ? "ON" : "OFF")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isDemoMode ? Color.blue.opacity(0.75) : Color.gray.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    // MARK: - NEW: Demo Mode Toggle Logic
    // Function: Handles demo mode state change and data clearing
    // Complexity: O(n) for deleting n plants, O(1) for badge reset
    // Correlation: When enabled, resets app to initial state for judge evaluation
    private func toggleDemoMode() {
        // Toggle state - O(1) write to UserDefaults
        isDemoMode.toggle()
        
        // Audio feedback (iPad compatible)
        VoiceNotificationManager.shared.playSoundEffect(isDemoMode ? .success : .notification)
        
        if isDemoMode {
            // Step 1: Delete all plants - O(n) complexity where n = plant count
            for plant in plants {
                modelContext.delete(plant)
            }
            // Save deletion to SwiftData - O(1) batch save
            try? modelContext.save()
            
            // Step 2: Reset all badges - O(1) operation
            EnhancedBadgeManager.shared.resetAllBadges()
            
            // Step 3: Reset onboarding flag - O(1) write
            hasCompletedOnboarding = false
            
            // Step 4: Trigger onboarding after 0.5s delay for smooth UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingOnboarding = true
            }
            
            print("Demo Mode ON: App reset to initial state")
        } else {
            print("Demo Mode OFF: Normal operation")
        }
    }
    
    // MARK: - Voice Reminder Section
    private var voiceReminderSection: some View {
        VStack(spacing: 12) {
            // Play button
            Button {
                voiceManager.checkAndAnnounce(plants: plants)
            } label: {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                    Text("Audio Summary")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    // MARK: - Today's Tasks Card
    private var todayTasksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Tasks")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 20) {
                statItem(icon: "drop.fill", color: .blue, value: statistics.needWater, label: "Need Water")
                Divider().frame(height: 40)
                statItem(icon: "mountain.2.fill", color: .brown, value: statistics.needFertilizer, label: "Fertilizer")
                Divider().frame(height: 40)
                statItem(icon: "leaf.fill", color: .green, value: statistics.healthy, label: "Healthy")
                Divider().frame(height: 40)
                statItem(icon: "exclamationmark.triangle.fill", color: .orange, value: statistics.needAttention, label: "Attention")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func statItem(icon: String, color: Color, value: Int, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Navigation Row
    private func navigationRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 50, height: 50)
                .background(iconColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Care Tips Card
    private var careTipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.max.fill")
                    .foregroundStyle(.yellow)
                Text("Care Tip of the Day")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(CareTipsManager.shared.tipOfTheDay.preview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Statistics Calculation
    // Function: Calculates plant statistics for today's tasks
    // Complexity: O(n) where n is number of plants
    private func calculateStatistics() -> PlantStatistics {
        var stats = PlantStatistics()
        
        for plant in plants {
            // Check watering needs - O(1) date comparison
            if Calendar.current.isDateInToday(plant.nextWateringDate) ||
                plant.nextWateringDate < Date() {
                stats.needWater += 1
            }
            
            // Check fertilizing needs - O(1) date comparison
            if Calendar.current.isDateInToday(plant.nextFertilizingDate) ||
                plant.nextFertilizingDate < Date() {
                stats.needFertilizer += 1
            }
            
            // Check health status - O(1) comparison
            if plant.healthScore > 70 {
                stats.healthy += 1
            } else {
                stats.needAttention += 1
            }
        }
        
        return stats
    }
    
    // Function: Generates badge subtitle text based on active/total count
    // Complexity: O(b) where b is badge count (typically small, ~8)
    private var badgeSubtitle: String {
        let activeCount = badgeManager.activeBadges(for: plants).count
        let totalUnlocked = badgeManager.unlockedBadges(for: plants).count
        
        if activeCount == totalUnlocked {
            return "\(activeCount) badge\(activeCount == 1 ? "" : "s") unlocked"
        } else {
            return "\(activeCount) active · \(totalUnlocked) total"
        }
    }
}

// MARK: - Statistics Structure
struct PlantStatistics {
    var needWater = 0
    var needFertilizer = 0
    var healthy = 0
    var needAttention = 0
}
