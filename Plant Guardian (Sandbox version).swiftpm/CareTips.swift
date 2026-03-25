// CareTipsDetailView.swift
// Detailed care tips and plant knowledge
import SwiftUI

struct CareTip: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let icon: String
    let category: String
}

class CareTipsManager {
    static let shared = CareTipsManager()
    
    let allTips: [CareTip] = [
        CareTip(
            title: "Light Requirements",
            content: "Most houseplants prefer bright, indirect sunlight. Direct sun can scorch leaves, while too little light slows growth and can cause leggy stems. Rotate plants weekly for even growth.",
            icon: "sun.max.fill",
            category: "Basics"
        ),
        CareTip(
            title: "Watering Wisdom",
            content: "Overwatering is the #1 cause of plant death. Always check soil moisture before watering. Most plants prefer soil to dry out slightly between waterings.",
            icon: "drop.fill",
            category: "Watering"
        ),
        CareTip(
            title: "Humidity Matters",
            content: "Many tropical houseplants thrive in 40-60% humidity. Mist leaves, use pebble trays, or group plants together to increase humidity around them.",
            icon: "cloud.fill",
            category: "Environment"
        ),
        CareTip(
            title: "Fertilizing Schedule",
            content: "Feed plants during growing season (spring/summer) with diluted liquid fertilizer every 2-4 weeks. Reduce or stop feeding in fall/winter when growth slows.",
            icon: "leaf.arrow.circlepath",
            category: "Nutrition"
        ),
        CareTip(
            title: "Repotting Guide",
            content: "Repot when roots grow out of drainage holes or plant becomes top-heavy. Spring is ideal. Choose pot 1-2 inches larger and use fresh potting mix.",
            icon: "arrow.up.circle.fill",
            category: "Maintenance"
        ),
        CareTip(
            title: "Pest Prevention",
            content: "Inspect plants regularly for pests. Isolate new plants for 2 weeks. Wipe leaves with damp cloth monthly. Neem oil spray works for most common pests.",
            icon: "ant.fill",
            category: "Health"
        )
    ]
    
    var tipOfTheDay: CareTip {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % allTips.count
        return allTips[index]
    }
}

extension CareTip {
    var preview: String {
        String(content.prefix(80)) + (content.count > 80 ? "..." : "")
    }
}

struct CareTipsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String = "All"
    
    private let categories = ["All", "Basics", "Watering", "Environment", "Nutrition", "Maintenance", "Health"]
    
    private var filteredTips: [CareTip] {
        if selectedCategory == "All" {
            return CareTipsManager.shared.allTips
        }
        return CareTipsManager.shared.allTips.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Tip of the day (highlighted)
                    tipOfTheDayCard
                        .padding(.horizontal)
                    
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    Text(category)
                                        .font(.subheadline)
                                        .fontWeight(selectedCategory == category ? .semibold : .regular)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? Color.green : Color.gray.opacity(0.2))
                                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // All tips
                    ForEach(filteredTips) { tip in
                        tipCard(tip)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.1), Color.green.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Care Tips")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var tipOfTheDayCard: some View {
        let tip = CareTipsManager.shared.tipOfTheDay
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Tip of the Day")
                    .font(.headline)
            }
            
            HStack(spacing: 12) {
                Image(systemName: tip.icon)
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                    .frame(width: 60, height: 60)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.headline)
                    
                    Text(tip.content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
        )
    }
    
    private func tipCard(_ tip: CareTip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tip.icon)
                    .foregroundStyle(.green)
                Text(tip.title)
                    .font(.headline)
                
                Spacer()
                
                Text(tip.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            Text(tip.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
