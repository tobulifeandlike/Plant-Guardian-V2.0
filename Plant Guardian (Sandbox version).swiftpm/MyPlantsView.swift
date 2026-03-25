// MyPlantsView.swift (Updated - Using System NavigationBar)
// Changes:
// - Removed custom navigation bar
// - Using system NavigationBar with toolbar
// - Three-dot menu in trailing toolbar position
// - Cleaner and more iOS-native design

import SwiftUI
import SwiftData

struct MyPlantsView_Enhanced: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plant.nextWateringDate) private var plants: [Plant]
    
    // MARK: - State Management
    @State private var selectedPlant: Plant?
    @State private var searchText = ""
    @State private var isSelectionMode = false
    @State private var selectedPlants: Set<Plant.ID> = []
    @State private var showingDeleteConfirmation = false
    @State private var sortOption: SortOption = .nextWatering
    
    // MARK: - Sort Options
    enum SortOption: String, CaseIterable {
        case nextWatering = "Next Watering"
        case name = "Name"
        case healthScore = "Health Score"
        case type = "Type"
    }
    
    // MARK: - Filtered & Sorted Plants
    private var filteredPlants: [Plant] {
        var filtered = plants
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.type.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch sortOption {
        case .nextWatering:
            return filtered.sorted { $0.nextWateringDate < $1.nextWateringDate }
        case .name:
            return filtered.sorted { $0.name < $1.name }
        case .healthScore:
            return filtered.sorted { $0.healthScore > $1.healthScore }
        case .type:
            return filtered.sorted { $0.type < $1.type }
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.green.opacity(0.1), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if filteredPlants.isEmpty {
                    emptyStateView
                } else {
                    plantList
                }
            }
        }
        .navigationTitle(isSelectionMode ? "\(selectedPlants.count) Selected" : "My Plants")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search plants...")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isSelectionMode {
                    Button("Cancel") {
                        exitSelectionMode()
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if !isSelectionMode {
                        Button {
                            enterSelectionMode()
                        } label: {
                            Label("Select Plants", systemImage: "checkmark.circle")
                        }
                        .disabled(plants.isEmpty)
                        
                        Divider()
                        
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    HStack {
                                        Text(option.rawValue)
                                        if sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Sort By", systemImage: "arrow.up.arrow.down")
                        }
                    } else {
                        Button {
                            selectAll()
                        } label: {
                            Label("Select All", systemImage: "checkmark.circle.fill")
                        }
                        
                        Button {
                            deselectAll()
                        } label: {
                            Label("Deselect All", systemImage: "circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $selectedPlant) { plant in
            PlantDetailView(plant: plant)
        }
        .alert("Delete Plants?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                exitSelectionMode()
            }
            Button("Delete \(selectedPlants.count) Plants", role: .destructive) {
                deleteSelectedPlants()
            }
        } message: {
            Text("Are you sure you want to delete \(selectedPlants.count) selected plant\(selectedPlants.count > 1 ? "s" : "")? This action cannot be undone.")
        }
    }
    
    // MARK: - Plant List
    private var plantList: some View {
        VStack(spacing: 0) {
            List {
                ForEach(filteredPlants) { plant in
                    HStack(spacing: 12) {
                        if isSelectionMode {
                            Image(systemName: selectedPlants.contains(plant.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedPlants.contains(plant.id) ? .blue : .gray)
                                .onTapGesture {
                                    toggleSelection(plant)
                                }
                        }
                        PlantCardView_Enhanced(
                            plant: plant,
                            isSelectionMode: isSelectionMode,
                            onDelete: {
                                deletePlant(plant)
                            }
                        )
                        .onTapGesture {
                            if isSelectionMode {
                                toggleSelection(plant)
                            } else {
                                selectedPlant = plant
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            if isSelectionMode && !selectedPlants.isEmpty {
                batchDeleteButton
            }
        }
    }
    
    // MARK: - Batch Delete Button
    private var batchDeleteButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete \(selectedPlants.count) Plant\(selectedPlants.count > 1 ? "s" : "")")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "leaf.fill" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.green.opacity(0.3))
            
            Text(searchText.isEmpty ? "No plants yet" : "No plants found")
                .font(.title2)
                .fontWeight(.semibold)
            
            if !searchText.isEmpty {
                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Selection Mode Actions
    private func enterSelectionMode() {
        isSelectionMode = true
        selectedPlants.removeAll()
    }
    
    private func exitSelectionMode() {
        isSelectionMode = false
        selectedPlants.removeAll()
    }
    
    private func toggleSelection(_ plant: Plant) {
        if selectedPlants.contains(plant.id) {
            selectedPlants.remove(plant.id)
        } else {
            selectedPlants.insert(plant.id)
        }
    }
    
    private func selectAll() {
        selectedPlants = Set(filteredPlants.map { $0.id })
    }
    
    private func deselectAll() {
        selectedPlants.removeAll()
    }
    
    // MARK: - Delete Actions
    private func deletePlant(_ plant: Plant) {
        withAnimation {
            modelContext.delete(plant)
            try? modelContext.save()
        }
    }
    
    private func deleteSelectedPlants() {
        withAnimation {
            for plantID in selectedPlants {
                if let plant = plants.first(where: { $0.id == plantID }) {
                    modelContext.delete(plant)
                }
            }
            try? modelContext.save()
            exitSelectionMode()
        }
    }
}

// MARK: - Enhanced Plant Card
struct PlantCardView_Enhanced: View {
    let plant: Plant
    let isSelectionMode: Bool
    let onDelete: () -> Void 
    var body: some View {
        HStack(spacing: 16) {
            // Plant photo
            if let photoData = plant.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(plant.urgencyLevel.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "leaf.fill")
                            .font(.largeTitle)
                            .foregroundStyle(plant.urgencyLevel.color)
                    }
            }
            
            // Plant info
            VStack(alignment: .leading, spacing: 6) {
                Text(plant.name)
                    .font(.headline)
                
                Text(plant.type)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                    Text(daysUntilWatering)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(plant.urgencyLevel.color)
                
                ProgressView(value: plant.healthScore / 100)
                    .tint(healthColor)
            }
            
            Spacer()
            VStack(alignment: .trailing, spacing: 12) {
                Spacer()
                
                Circle()
                    .fill(plant.urgencyLevel.color)
                    .frame(width: 12, height: 12)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var daysUntilWatering: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: plant.nextWateringDate).day ?? 0
        if days < 0 {
            return "Overdue by \(abs(days)) days"
        } else if days == 0 {
            return "Water today"
        } else {
            return "Water in \(days) days"
        }
    }
    
    private var healthColor: Color {
        if plant.healthScore > 80 { return .green }
        if plant.healthScore > 50 { return .yellow }
        return .orange
    }
}

