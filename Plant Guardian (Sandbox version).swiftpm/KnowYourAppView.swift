// KnowYourAppView.swift

import SwiftUI

struct KnowYourAppView: View {
    @State private var selectedTab: GuideTab = .gettingStarted
    
    enum GuideTab: String, CaseIterable {
        case gettingStarted = "Getting Started"
        case features = "Features"
        case tips = "Tips & Tricks"
        case releaseNotes = "Version Update"
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Tab Selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    gettingStartedView
                        .tag(GuideTab.gettingStarted)
                    
                    featuresView
                        .tag(GuideTab.features)
                    
                    tipsAndTricksView
                        .tag(GuideTab.tips)
                    
                    releaseNotesView
                        .tag(GuideTab.releaseNotes)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationTitle("Know Your App")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GuideTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundStyle(selectedTab == tab ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Getting Started View
    private var gettingStartedView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerCard(
                    icon: "hand.wave.fill",
                    title: "Welcome to Plant Guardian!",
                    subtitle: "Your personal AI-powered plant care assistant"
                )
                
                stepCard(
                    number: 1,
                    title: "Add Your First Plant",
                    description: "Tap the '+' button on the home screen to add a new plant. Take a photo for health tracking and enter the plant type.",
                    icon: "plus.circle.fill"
                )
                
                stepCard(
                    number: 2,
                    title: "Set Watering Schedule",
                    description: "Choose how often your plant needs water. The app will remind you when it's time to water.",
                    icon: "drop.fill"
                )
                
                stepCard(
                    number: 3,
                    title: "Track Plant Health",
                    description: "View your plant's health score based on AI analysis of the uploaded photo. Keep all plants above 70% for optimal growth!",
                    icon: "heart.fill"
                )
                
                stepCard(
                    number: 4,
                    title: "Unlock Achievements",
                    description: "Earn badges by taking care of your plants consistently. Collect them all!",
                    icon: "star.fill"
                )
            }
            .padding()
        }
    }
    
    // MARK: - Features View
    private var featuresView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard(
                    icon: "sparkles",
                    title: "Powerful Features",
                    subtitle: "Everything you need to nurture your plants"
                )
                
                featureCard(
                    icon: "brain.head.profile",
                    title: "AI Health Analysis",
                    description: "Vision framework analyzes leaf color and detects damage to calculate health scores (0-100).",
                    color: .purple
                )
                
                featureCard(
                    icon: "speaker.wave.2.fill",
                    title: "Voice Reminders",
                    description: "Get audio announcements for watering tasks, fertilizing schedules, and plant health alerts.",
                    color: .blue
                )
                
                featureCard(
                    icon: "scenekit",
                    title: "3D Virtual Garden",
                    description: "View your plants in a beautiful 3D garden scene using SceneKit with USDZ models.",
                    color: .green
                )
                
                featureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Kalman Filter Prediction",
                    description: "Advanced algorithm predicts future health trends based on historical data.",
                    color: .orange
                )
                
                featureCard(
                    icon: "star.circle.fill",
                    title: "Achievement System",
                    description: "Unlock 8+ badges by reaching milestones like '10 Plants' or 'Green Thumb Master'.",
                    color: .yellow
                )
                
                featureCard(
                    icon: "lightbulb.max.fill",
                    title: "Daily Care Tips",
                    description: "Learn plant care best practices with rotating tips on watering, light, and more.",
                    color: .mint
                )
            }
            .padding()
        }
    }
    
    // MARK: - Tips & Tricks View
    private var tipsAndTricksView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard(
                    icon: "lightbulb.fill",
                    title: "Pro Tips",
                    subtitle: "Get the most out of Plant Guardian"
                )
                
                tipCard(
                    title: "Take Clear Photos",
                    tip: "For best AI analysis, take photos in natural light showing the entire plant. Avoid blurry images."
                )
                
                tipCard(
                    title: "Customize Watering Intervals",
                    tip: "Adjust watering schedules based on your local climate. Desert plants need less water than tropical ones."
                )
                
                tipCard(
                    title: "Use Voice Reminders",
                    tip: "Tap 'Play Voice Reminder' daily to hear which plants need attention. Replay anytime with the Replay button."
                )
                
                tipCard(
                    title: "Monitor Health Trends",
                    tip: "Check the health prediction chart to see if your plant is improving or declining over the next 7 days."
                )
                
                tipCard(
                    title: "Unlock All Badges",
                    tip: "Aim for 'Green Thumb Master' by keeping all plants at 100% health. Check progress in My Badges."
                )
                
                tipCard(
                    title: "Batch Delete Plants",
                    tip: "In My Plants, tap the menu (•••) and select 'Select Plants' to delete multiple plants at once."
                )
                
                tipCard(
                    title: "iPad Compatibility",
                    tip: "Sound effects replace haptic feedback on iPad. Enjoy audio cues for actions and achievements!"
                )
            }
            .padding()
        }
    }
    
    // MARK: - Release Notes View
    private var releaseNotesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerCard(
                    icon: "square.stack.3d.up.fill",
                    title: "Release Notes",
                    subtitle: "Latest updates and improvements"
                )
                
                releaseSection(
                    version: "2.0",
                    date: "January 2026",
                    features: [
                        "Kalman Filter: Advanced health trend prediction algorithm",
                        "Enhanced Voice System: Replay button and improved announcements",
                        "Badge Unlock Animations: Celebratory popups with sound effects",
                        "Batch Delete: Select and delete multiple plants at once",
                        "iPad Optimization: Sound effects for all interactions",
                        "Bug Fixes: Corrected unhealthy plant health score detection",
                        "Sandbox version"
                    ]
                )
                
                releaseSection(
                    version: "1.0",
                    date: "December 2025",
                    features: [
                        "Initial Release: Add and track plants",
                        "AI Health Analysis: Vision framework integration",
                        "3D Garden View: SceneKit visualization",
                        "Voice Notifications: TTS reminders",
                        "Achievement System: 8 unlockable badges",
                        "Care Tips Database: Daily plant care advice",
                        "Sandbox version"
                    ]
                )
            }
            .padding()
        }
    }
    
    // MARK: - Reusable Components
    
    private func headerCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func stepCard(number: Int, title: String, description: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text("\(number)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(.blue)
                    Text(title)
                        .font(.headline)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func featureCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func tipCard(title: String, tip: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(tip)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func releaseSection(version: String, date: String, features: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("V \(version)")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.blue)
                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func roadmapItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.orange)
            Text(text)
                .font(.subheadline)
        }
    }
}

