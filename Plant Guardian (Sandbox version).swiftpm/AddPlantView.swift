// Add_Plant_View.swift

import SwiftUI
import SwiftData

struct AddPlantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var nickname = ""
    @State private var typeInput = ""
    @State private var recognizedPlant: PlantInfo?
    @State private var wateringInterval = 7
    @State private var fertilizingInterval = 30
    @State private var photoData: Data?
    @State private var isAnalyzingPhoto = false
    @State private var showingError = false 
    @State private var errorMessage = ""
    @State private var showingSamplePhotos = false
    
    private let recognizer = PlantTypeRecognizer()
    private let healthAnalyzer = PlantHealthAnalyzer()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Plant Identity") {
                    TextField("Nickname (e.g., Lucky)", text: $nickname)
                        .autocapitalization(.words)
                    
                    TextField("Type (e.g., UFO Plant)", text: $typeInput)
                        .autocapitalization(.words)
                        .onChange(of: typeInput) { _, newValue in
                            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 {
                                recognizedPlant = recognizer.recognizePlantType(from: newValue)
                            } else {
                                recognizedPlant = nil
                            }
                        }
                    
                    if let recognized = recognizedPlant {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading) {
                                Text("Recognized: \(recognized.type)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(recognized.scientificName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Section("Watering and Fertilizing Schedule") {
                    Stepper("Watering: Every \(wateringInterval) days", value: $wateringInterval, in: 1...30)
                    Stepper("Fertilizing: Every \(fertilizingInterval) days", value: $fertilizingInterval, in: 1...100)
                }
                
                if let recognized = recognizedPlant {
                    Section("Care Tips") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Light: \(recognized.lightRequirement)", systemImage: "sun.max.fill")
                                .font(.subheadline)
                            
                            Text(recognized.careTips)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                Section("Photo (for health tracking)") {
                    Button {
                        showingSamplePhotos = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.stack.fill")
                                .foregroundStyle(.green)
                            Text("Select Sample Photo")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if isAnalyzingPhoto {
                        HStack {
                            ProgressView()
                            Text("Analyzing plant health...")
                                .font(.caption)
                        }
                    }
                    
                    if let data = photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                Section {
                    Button("Add Plant") {
                        addPlant()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingSamplePhotos) {
                SamplePhotoLibraryView(selectedPhotoData: $photoData, isPresented: $showingSamplePhotos)
                    .onDisappear {
                        if let data = photoData {
                            Task {
                                isAnalyzingPhoto = true
                                _ = await healthAnalyzer.analyzeHealth(from: data)
                                isAnalyzingPhoto = false
                            }
                        }
                    }
            }
        }
    }
    
    private var isFormValid: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !typeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addPlant() {
        guard isFormValid else {
            errorMessage = "Please fill in plant name and type."
            showingError = true
            return
        }
        
        let finalType = recognizedPlant?.type ?? typeInput
        let plant = Plant(
            name: nickname,
            type: finalType,
            wateringInterval: wateringInterval,
            fertilizingInterval: fertilizingInterval,
            photoData: photoData
        )
        
        if let data = photoData {
            Task {
                let result = await healthAnalyzer.analyzeHealth(from: data)
                plant.healthScore = result.analysisScore
                do {
                    modelContext.insert(plant)
                    try modelContext.save()
                    dismiss()
                } catch {
                    print("Failed to save plant: \(error)")
                }
            }
        } else {
            do {
                modelContext.insert(plant)
                try modelContext.save()
                dismiss()
            } catch {
                print("Failed to save plant: \(error)")
            }
        }
    }
}

struct PlantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let plant: Plant
    @State private var showingWaterConfirmation = false
    @State private var showingFertilizeConfirmation = false
    @State private var showingDeleteAlert = false
    @State private var notesText = ""
    
    @State private var prediction: HealthPrediction?
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
               
                    if let photoData = plant.photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 10)
                    }
                    healthAnalysisSection
                    plantInfoSection
                    notesSection
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(plant.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .onAppear {
                prediction = plant.getPredictionWithKalman()
            }
            .alert("Water Plant?", isPresented: $showingWaterConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Confirm") {
                    waterPlant()
                }
            } message: {
                Text("Mark \(plant.name) as watered today?")
            }
            .alert("Fertilize Plant?", isPresented: $showingFertilizeConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Confirm") {
                    fertilizePlant()
                }
            } message: {
                Text("Mark \(plant.name) as fertilized today?")
            }
            .alert("Remove Plant?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    deletePlant()
                }
            } message: {
                Text("Are you sure you want to remove \(plant.name)?")
            }
        }
    }
    private var healthAnalysisSection: some View {
        GroupBox {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.gray)
                    Text("Health Analysis & Prediction")
                        .font(.headline)
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    aiAnalysisCard
                    kalmanPredictionCard
                }
                
                Divider()
                
                wateringRecommendationCard
            }
        }
    }
    
    private var aiAnalysisCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "camera.viewfinder")
                    .font(.caption2)
                Text("AI Analysis")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.15))
            .clipShape(Capsule())
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: plant.healthScore / 100)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: plant.healthScore)
                
                VStack(spacing: 2) {
                    Text("\(Int(plant.healthScore))")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text("Current Health")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    private var kalmanPredictionCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption2)
                Text("7-Day Prediction")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.purple)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.15))
            .clipShape(Capsule())
            if let prediction = prediction {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: prediction.predicted_score / 100)
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: prediction.predicted_score)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(prediction.predicted_score))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(prediction.trend.swiftUIColor)
                        Text("%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: prediction.trend.icon)
                        .font(.caption)
                    Text(prediction.trend.description)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(prediction.trend.swiftUIColor)
            } else {
                ProgressView()
                    .frame(width: 100, height: 100)
            }
            
            Text("In 7 Days")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var wateringRecommendationCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                Text("Smart Watering Recommendation")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if let prediction = prediction {
                VStack(spacing: 8) {
                    HStack {
                        Text("Your Setting:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Every \(plant.wateringInterval) days")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    Divider()
                    HStack {
                        Text("Recommended:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        let recommendedDays = plant.getRecommendedWateringDays()
                        let adjustment = recommendedDays - plant.wateringInterval
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("In \(recommendedDays) days")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                            if adjustment != 0 {
                                Text("(\(adjustment > 0 ? "+" : "")\(adjustment) days)")
                                    .font(.caption2)
                                    .foregroundStyle(adjustmentColor(adjustment))
                            }
                        }
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue.opacity(0.7))
                        
                        Text(adjustmentReason(prediction: prediction))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            } else {
                ProgressView()
            }
        }
        .padding()
        .background(Color.blue.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func adjustmentReason(prediction: HealthPrediction) -> String {
        let healthChange = prediction.predicted_score - plant.healthScore
        
        if healthChange < -5 {
            return "Predicted declining health → water earlier"
        } else if healthChange > 5 {
            return "Predicted improving health → can wait longer"
        } else {
            return "Predicted stable health → keep current schedule"
        }
    }
    
    private func adjustmentColor(_ adjustment: Int) -> Color {
        if adjustment < 0 {
            return .orange
        } else if adjustment > 0 {
            return .green
        } else {
            return .blue
        }
    }
    private var plantInfoSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "Type", value: plant.type, icon: "leaf.fill")
                InfoRow(label: "Last Watered", 
                        value: plant.lastWatered.formatted(date: .abbreviated, time: .omitted), 
                        icon: "calendar")
                InfoRow(label: "Next Watering", 
                        value: plant.nextWateringDate.formatted(date: .abbreviated, time: .omitted), 
                        icon: "drop.fill")
                Divider()
                InfoRow(label: "Last Fertilized",
                        value: plant.lastFertilized.formatted(date: .abbreviated, time: .omitted),
                        icon: "calendar")
                InfoRow(label: "Next Fertilizing",
                        value: plant.nextFertilizingDate.formatted(date: .abbreviated, time: .omitted),
                        icon: "mountain.2.fill")
            }
        }
    }
    
    private var notesSection: some View {
        GroupBox("Notes") {
            TextEditor(text: $notesText)
                .frame(minHeight: 100)
                .onAppear {
                    notesText = plant.notes
                }
                .onChange(of: notesText) { _, newValue in
                    plant.notes = newValue
                    try? modelContext.save()
                }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showingWaterConfirmation = true
            } label: {
                Label("Water", systemImage: "drop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button {
                showingFertilizeConfirmation = true
            } label: {
                Label("Fertilize", systemImage: "mountain.2.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brown)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func waterPlant() {
        do {
            plant.lastWatered = Date()
            plant.updateWateringDate()
            try modelContext.save()
            
            prediction = plant.getPredictionWithKalman()
            
            VoiceNotificationManager.shared.celebrateWatering(plantName: plant.name)
            dismiss()
        } catch {
            print("Failed to update plant: \(error)")
        }
    }
    
    private func fertilizePlant() {
        do {
            plant.markAsFertilized()
            try modelContext.save()
            VoiceNotificationManager.shared.announceImmediate("Great! \(plant.name) has been fertilized.")
            dismiss()
        } catch {
            print("Failed to fertilize plant: \(error)")
        }
    }
    
    private func deletePlant() {
        do {
            modelContext.delete(plant)
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete plant: \(error)")
        }
    }
}

// MARK: - InfoRow
struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct SamplePhotoLibraryView: View {
    @Binding var selectedPhotoData: Data?
    @Binding var isPresented: Bool
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private let samplePhotos: [SamplePhoto] = [
        SamplePhoto(
            id: "ufo plant",
            name: "UFO Plant",
            description: "Vibrant green leaves",
            imageName: "ufo plant",
            plantType: .greenLeaf,
            healthScore: 90,
            isRealPhoto: true
        ),
        SamplePhoto(
            id: "green onion",
            name: "Green Onion",
            description: "Not growing well",
            imageName: "green onion",
            plantType: .greenLeaf,
            healthScore: 50,
            isRealPhoto: true
        ),
        SamplePhoto(
            id: "string of pearls",
            name: "String of Pearls",
            description: "Lovely plant",
            imageName: "string of pearls",
            plantType: .variegated,
            healthScore: 86,
            isRealPhoto: true
        ),
        SamplePhoto(
            id: "baby rubberplant",
            name: "Baby Rubberplant",
            description: "Enjoying the sunlight",
            imageName: "baby rubberplant",
            plantType: .variegated,
            healthScore: 92,
            isRealPhoto: true
        )
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundStyle(.green)
                            Text("Sample Plants")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text("Select a plant photo to experience AI health analysis and Kalman predictions.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(samplePhotos) { photo in
                            SamplePhotoCard(photo: photo) {
                                selectPhoto(photo)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sample Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
    
    private func selectPhoto(_ photo: SamplePhoto) {
        if let imageName = photo.imageName,
           let image = UIImage(named: imageName),
           let data = image.jpegData(compressionQuality: 0.85) {
            selectedPhotoData = data
            print("Loaded real photo: \(imageName)")
        } else {
            let generatedImage = PlantPhotoGenerator.generate(for: photo)
            selectedPhotoData = generatedImage.jpegData(compressionQuality: 0.85)
            print("Generated fallback image for: \(photo.name)")
        }
        isPresented = false
    }
}

// MARK: - Sample Photo Model
struct SamplePhoto: Identifiable {
    let id: String
    let name: String
    let description: String
    let imageName: String?
    let plantType: PlantPhotoType
    let healthScore: Int
    let isRealPhoto: Bool
}

enum PlantPhotoType {
    case greenLeaf
    case variegated
    case darkGreen
    case tropical
    case striped
}

// MARK: - Sample Photo Card
struct SamplePhotoCard: View {
    let photo: SamplePhoto
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    plantPreview
                    
                    VStack(spacing: 4) {
                        if photo.isRealPhoto {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption2)
                                Text("Real")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.9))
                            .clipShape(Capsule())
                        }
                        
                        Text("\(photo.healthScore)%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(healthColor.opacity(0.9))
                            .clipShape(Capsule())
                    }
                    .padding(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(photo.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(photo.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var plantPreview: some View {
        if let imageName = photo.imageName,
           let image = UIImage(named: imageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            generatedPlaceholder
        }
    }
    
    private var generatedPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 140)
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: plantIcon)
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(photo.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
    }
    
    private var gradientColors: [Color] {
        switch photo.plantType {
        case .greenLeaf:
            return [Color(red: 0.2, green: 0.7, blue: 0.3), Color(red: 0.15, green: 0.6, blue: 0.25)]
        case .variegated:
            return [Color(red: 0.5, green: 0.8, blue: 0.5), Color(red: 0.6, green: 0.85, blue: 0.6)]
        case .darkGreen:
            return [Color(red: 0.1, green: 0.5, blue: 0.15), Color(red: 0.05, green: 0.45, blue: 0.1)]
        case .tropical:
            return [Color(red: 0.15, green: 0.65, blue: 0.2), Color(red: 0.1, green: 0.6, blue: 0.15)]
        case .striped:
            return [Color(red: 0.4, green: 0.75, blue: 0.4), Color(red: 0.5, green: 0.8, blue: 0.5)]
        }
    }
    
    private var plantIcon: String {
        switch photo.plantType {
        case .greenLeaf: return "leaf.fill"
        case .variegated: return "leaf"
        case .darkGreen: return "tree.fill"
        case .tropical: return "figure.walk"
        case .striped: return "wind"
        }
    }
    
    private var healthColor: Color {
        if photo.healthScore >= 90 { return .green }
        if photo.healthScore >= 80 { return .yellow }
        return .orange
    }
    
    private var borderColor: Color {
        photo.isRealPhoto ? Color.blue.opacity(0.4) : healthColor.opacity(0.3)
    }
    
    private var borderWidth: CGFloat {
        photo.isRealPhoto ? 2 : 1
    }
}

// MARK: - Plant Photo Generator
struct PlantPhotoGenerator {
    static func generate(for photo: SamplePhoto) -> UIImage {
        let size = CGSize(width: 800, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            drawBackground(cgContext, size: size, type: photo.plantType)
            drawLeafTexture(cgContext, size: size, type: photo.plantType)
            drawHealthFeatures(cgContext, size: size, healthScore: photo.healthScore)
        }
    }
    
    private static func drawBackground(_ context: CGContext, size: CGSize, type: PlantPhotoType) {
        let colors: [UIColor]
        
        switch type {
        case .greenLeaf:
            colors = [
                UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0),
                UIColor(red: 0.15, green: 0.65, blue: 0.25, alpha: 1.0)
            ]
        case .variegated:
            colors = [
                UIColor(red: 0.5, green: 0.8, blue: 0.5, alpha: 1.0),
                UIColor(red: 0.6, green: 0.85, blue: 0.6, alpha: 1.0),
                UIColor(red: 0.9, green: 0.95, blue: 0.9, alpha: 1.0)
            ]
        case .darkGreen:
            colors = [
                UIColor(red: 0.1, green: 0.5, blue: 0.15, alpha: 1.0),
                UIColor(red: 0.05, green: 0.45, blue: 0.1, alpha: 1.0)
            ]
        case .tropical:
            colors = [
                UIColor(red: 0.15, green: 0.65, blue: 0.2, alpha: 1.0),
                UIColor(red: 0.1, green: 0.6, blue: 0.15, alpha: 1.0)
            ]
        case .striped:
            colors = [
                UIColor(red: 0.4, green: 0.75, blue: 0.4, alpha: 1.0),
                UIColor(red: 0.5, green: 0.8, blue: 0.5, alpha: 1.0)
            ]
        }
        
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors.map { $0.cgColor } as CFArray,
            locations: nil
        )
        
        context.drawLinearGradient(
            gradient!,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: size.width, y: size.height),
            options: []
        )
    }
    
    private static func drawLeafTexture(_ context: CGContext, size: CGSize, type: PlantPhotoType) {
        context.setAlpha(0.3)
        
        for _ in 0..<8 {
            let x = CGFloat.random(in: 50...size.width - 50)
            let y = CGFloat.random(in: 50...size.height - 50)
            let width = CGFloat.random(in: 150...350)
            let height = CGFloat.random(in: 100...250)
            
            let leafColor: UIColor
            switch type {
            case .greenLeaf:
                leafColor = UIColor(red: 0.1, green: 0.6, blue: 0.2, alpha: 0.5)
            case .variegated:
                leafColor = Bool.random() ?
                UIColor(red: 0.8, green: 0.9, blue: 0.8, alpha: 0.6) :
                UIColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 0.5)
            case .darkGreen:
                leafColor = UIColor(red: 0.05, green: 0.4, blue: 0.1, alpha: 0.6)
            case .tropical:
                leafColor = UIColor(red: 0.1, green: 0.55, blue: 0.15, alpha: 0.5)
            case .striped:
                leafColor = UIColor(red: 0.3, green: 0.65, blue: 0.3, alpha: 0.5)
            }
            
            context.setFillColor(leafColor.cgColor)
            context.fillEllipse(in: CGRect(x: x, y: y, width: width, height: height))
        }
        
        context.setAlpha(1.0)
    }
    
    private static func drawHealthFeatures(_ context: CGContext, size: CGSize, healthScore: Int) {
        if healthScore >= 90 {
            context.setFillColor(UIColor.white.withAlphaComponent(0.15).cgColor)
            context.fillEllipse(in: CGRect(x: 100, y: 100, width: 300, height: 300))
        } else if healthScore < 80 {
            context.setFillColor(UIColor.black.withAlphaComponent(0.1).cgColor)
            for _ in 0..<3 {
                let x = CGFloat.random(in: 100...600)
                let y = CGFloat.random(in: 100...600)
                context.fillEllipse(in: CGRect(x: x, y: y, width: 80, height: 80))
            }
        }
    }
}

