// TodayTasksDetailView.swift
import SwiftUI

struct TodayTasksDetailView: View {
    let plants: [Plant]
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Computed Properties
    private var plantsNeedingWater: [Plant] {
        plants.filter {
            Calendar.current.isDateInToday($0.nextWateringDate) ||
            $0.nextWateringDate < Date()
        }.sorted { $0.nextWateringDate < $1.nextWateringDate }
    }
    private var plantsNeedingFertilizer: [Plant] {
        plants.filter {
            Calendar.current.isDateInToday($0.nextFertilizingDate) ||
            $0.nextFertilizingDate < Date()
        }.sorted { $0.nextFertilizingDate < $1.nextFertilizingDate }
    }
    private var healthyPlants: [Plant] {
        plants.filter { $0.healthScore > 70 }
    }
    private var plantsNeedingAttention: [Plant] {
        plants.filter { $0.healthScore <= 70 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary card
                    summaryCard
                        .padding(.horizontal)
                    
                    // Plants needing water
                    if !plantsNeedingWater.isEmpty {
                        plantSection(
                            title: "Need Water Today",
                            plants: plantsNeedingWater,
                            icon: "drop.fill",
                            color: .blue
                        )
                    }
                    
                    // Plants needing fertilizer
                    if !plantsNeedingFertilizer.isEmpty {
                        plantSection(
                            title: "Need Fertilizer",
                            plants: plantsNeedingFertilizer,
                            icon: "mountain.2.fill",
                            color: .brown
                        )
                    }
                    
                    // Plants needing attention
                    if !plantsNeedingAttention.isEmpty {
                        plantSection(
                            title: "Need Attention",
                            plants: plantsNeedingAttention,
                            icon: "exclamationmark.triangle.fill",
                            color: .orange
                        )
                    }
                    
                    // Healthy plants
                    if !healthyPlants.isEmpty {
                        plantSection(
                            title: "Healthy Plants",
                            plants: healthyPlants,
                            icon: "leaf.fill",
                            color: .green
                        )
                    }
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.green.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Today's Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Summary Card (Updated with Fertilizer)
    private var summaryCard: some View {
        VStack(spacing: 16) {
            Text("Summary")
                .font(.headline)
            
            HStack(spacing: 12) {
                // Water
                statItem(
                    icon: "drop.fill",
                    color: .blue,
                    value: plantsNeedingWater.count,
                    label: "Water"
                )
                
                Divider().frame(height: 40)
                
                // NEW: Fertilizer
                statItem(
                    icon: "mountain.2.fill",
                    color: .brown,
                    value: plantsNeedingFertilizer.count,
                    label: "Fertilize"
                )
                
                Divider().frame(height: 40)
                
                // Healthy
                statItem(
                    icon: "leaf.fill",
                    color: .green,
                    value: healthyPlants.count,
                    label: "Healthy"
                )
                
                Divider().frame(height: 40)
                
                // Attention
                statItem(
                    icon: "exclamationmark.triangle.fill",
                    color: .orange,
                    value: plantsNeedingAttention.count,
                    label: "Attention"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Stat Item
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
    
    // MARK: - Plant Section
    private func plantSection(title: String, plants: [Plant], icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                // Count badge
                Text("\(plants.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            ForEach(plants) { plant in
                TaskPlantCard(plant: plant, sectionColor: color)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Task Plant Card Component
struct TaskPlantCard: View {
    let plant: Plant
    let sectionColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Plant icon or photo
            if let photoData = plant.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(sectionColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(sectionColor)
                    }
            }
            
            // Plant info
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(plant.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Task-specific info
                HStack(spacing: 12) {
                    // Water status
                    if needsWater(plant) {
                        TaskBadge(
                            icon: "drop.fill",
                            text: wateringStatus(plant),
                            color: .blue
                        )
                    }
                    
                    // Fertilizer status
                    if needsFertilizer(plant) {
                        TaskBadge(
                            icon: "mountain.2.fill",
                            text: fertilizingStatus(plant),
                            color: .brown
                        )
                    }
                }
            }
            
            Spacer()
            
            // Health score
            VStack(spacing: 4) {
                Text("\(Int(plant.healthScore))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(healthColor(plant.healthScore))
                
                Image(systemName: healthIcon(plant.healthScore))
                    .font(.caption2)
                    .foregroundStyle(healthColor(plant.healthScore))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(sectionColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Functions
    
    private func needsWater(_ plant: Plant) -> Bool {
        Calendar.current.isDateInToday(plant.nextWateringDate) ||
        plant.nextWateringDate < Date()
    }
    
    private func needsFertilizer(_ plant: Plant) -> Bool {
        Calendar.current.isDateInToday(plant.nextFertilizingDate) ||
        plant.nextFertilizingDate < Date()
    }
    
    private func wateringStatus(_ plant: Plant) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: plant.nextWateringDate).day ?? 0
        if days < 0 {
            return "Overdue"
        } else {
            return "Today"
        }
    }
    
    private func fertilizingStatus(_ plant: Plant) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: plant.nextFertilizingDate).day ?? 0
        if days < 0 {
            return "Overdue"
        } else {
            return "Today"
        }
    }
    
    private func healthColor(_ score: Double) -> Color {
        if score > 80 { return .green }
        if score > 50 { return .yellow }
        return .orange
    }
    
    private func healthIcon(_ score: Double) -> String {
        if score > 80 { return "heart.fill" }
        if score > 50 { return "heart" }
        return "heart.slash"
    }
}

// MARK: - Task Badge Component
struct TaskBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}
