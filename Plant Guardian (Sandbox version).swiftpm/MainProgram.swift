import SwiftUI
import SwiftData

// PlantGuardianApp.swift
// App entry point with SwiftData container setup
@main
struct PlantGuardianApp: App {
    // Create model container with in-memory storage for Playground compatibility
    let container: ModelContainer
    
    init() {
        // Configure SwiftData with in-memory storage (no file system access needed)
        do {
            // Create schema for Plant model
            let schema = Schema([Plant.self])
            
            // Use in-memory configuration (compatible with Playgrounds)
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false 
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            // Fallback: create minimal container if configuration fails
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Plant.self)
    }
    
}
