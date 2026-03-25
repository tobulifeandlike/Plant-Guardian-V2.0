// MoreFunctionsView.swift

import SwiftUI

struct MoreFunctionsView: View {
    private let upcomingFeatures: [UpcomingFeature] = [
        UpcomingFeature(
            icon: "cloud.sun.rain.fill",
            title: "Weather Info Use",
            description: "Auto-adjust watering based on local weather forecast",
            status: .inDevelopment
        ),
        UpcomingFeature(
            icon: "chart.line.uptrend.xyaxis",
            title: "Growth Analytics",
            description: "Track plant health trends over time with detailed charts",
            status: .inDevelopment
        ),
        UpcomingFeature(
            icon: "rectangle.stack.fill.badge.plus",
            title: "Widgets",
            description: "View your garden status directly on the home screen",
            status: .inDevelopment
        ),
        UpcomingFeature(
            icon: "arkit",
            title: "AR Virtual Garden",
            description: "Visualize plants in your space with ARKit before buying",
            status: .planned
        ),
        UpcomingFeature(
            icon: "person.2.fill",
            title: "Community Sharing",
            description: "Share your garden progress and tips with other users",
            status: .planned
        ),
        UpcomingFeature(
            icon: "applewatch",
            title: "Apple Watch App",
            description: "Quick watering reminders on your wrist",
            status: .planned
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                        .padding(.horizontal)
                        .padding(.top, 20)
                    VStack(spacing: 16) {
                        ForEach(upcomingFeatures) { feature in
                            FeatureCard(feature: feature)
                                .padding(.horizontal)
                        }
                    }
                    Color.clear.frame(height: 40)
                }
            }
        }
        .navigationTitle("More Functions")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Exciting Features Coming Soon!")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("More functions to be unlocked in the future. Stay tuned for updates!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .orange.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct FeatureCard: View {
    let feature: UpcomingFeature
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(feature.status.color.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: feature.icon)
                    .font(.title2)
                    .foregroundStyle(feature.status.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(feature.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    statusBadge(for: feature.status)
                }
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func statusBadge(for status: FeatureStatus) -> some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundStyle(status.color)
            .clipShape(Capsule())
    }
}

struct UpcomingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let status: FeatureStatus
}

enum FeatureStatus: String {
    case planned = "Planned"
    case inDevelopment = "In Dev"
    case comingSoon = "Soon"
    
    var color: Color {
        switch self {
        case .planned:
            return .blue
        case .inDevelopment:
            return .orange
        case .comingSoon:
            return .green
        }
    }
}

