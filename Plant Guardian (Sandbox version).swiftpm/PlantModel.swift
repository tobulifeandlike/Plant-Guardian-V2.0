// Plant_Model.swift

import Foundation
import SwiftData
import SwiftUI

@Model 
final class Plant {
    var id: UUID
    var name: String
    var type: String
    var lastWatered: Date
    var wateringInterval: Int
    var lastFertilized: Date 
    var fertilizingInterval: Int
    var healthScore: Double
    var photoData: Data?
    var notes: String
    
    // Computed properties
    var nextWateringDate: Date 
    var nextFertilizingDate: Date
    
    var urgencyLevel: UrgencyLevel {
        let hoursUntilWatering = nextWateringDate.timeIntervalSince(Date()) / 3600
        if hoursUntilWatering < 0 { return .overdue }
        if hoursUntilWatering < 24 { return .urgent }
        if hoursUntilWatering < 48 { return .soon }
        return .healthy
    }
    
    var fertilizingUrgency: UrgencyLevel {
        let hoursUntilFertilizing = nextFertilizingDate.timeIntervalSince(Date()) / 3600
        if hoursUntilFertilizing < 0 { return .overdue }
        if hoursUntilFertilizing < 24 * 7 { return .urgent }
        if hoursUntilFertilizing < 24 * 14 { return .soon }
        return .healthy
    }
    
    init(name: String, type: String, wateringInterval: Int, fertilizingInterval: Int, photoData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.lastWatered = Date()
        self.lastFertilized = Date()
        self.wateringInterval = wateringInterval
        self.healthScore = 85.0
        self.fertilizingInterval = fertilizingInterval
        self.photoData = photoData
        self.notes = ""
        
        self.nextWateringDate = Calendar.current.date(
            byAdding: .day, 
            value: wateringInterval, 
            to: Date()
        ) ?? Date()
        
        self.nextFertilizingDate = Calendar.current.date(
            byAdding: .day, 
            value: fertilizingInterval, 
            to: Date()
        ) ?? Date()
    }
    
    // MARK: - Existing Methods
    func updateWateringDate() {
        self.nextWateringDate = Calendar.current.date(
            byAdding: .day,
            value: wateringInterval,
            to: lastWatered
        ) ?? Date()
    }
    
    func updateFertilizingDate() {
        self.nextFertilizingDate = Calendar.current.date(
            byAdding: .day,
            value: fertilizingInterval,
            to: lastFertilized
        ) ?? Date()
    }
    
    func markAsFertilized() {
        self.lastFertilized = Date()
        updateFertilizingDate()
    }
    
    func getPredictionWithKalman() -> HealthPrediction {
        let analysis_score = self.healthScore
        
        let kalman = KalmanHealthEstimator(initialHealth: analysis_score)
        
        let observations = generateSimulatedObservations()
        
        for (index, observation) in observations.enumerated() {
            kalman.update(observation: observation)
        }
        
        let wateringSchedule: [Int: Double] = [
            self.wateringInterval: 0.8  
        ]
        
        let prediction = kalman.forecast(
            days: 7,
            wateringSchedule: wateringSchedule,
            analysis_score: analysis_score
        )
        
        return prediction
    }
    
    private func generateSimulatedObservations() -> [Double] {
        let currentHealth = self.healthScore
        var observations: [Double] = []
        
        for i in 0..<5 {
            let dayOffset = Double(5 - i)
            let baseChange: Double
            
            if currentHealth > 80 {
                baseChange = Double.random(in: -1.0...2.0)  
            } else if currentHealth > 60 {
                baseChange = Double.random(in: -2.0...2.0)  
            } else {
                baseChange = Double.random(in: -3.0...1.0)  
            }
            
            let noise = Double.random(in: -2.0...2.0)
            let observedHealth = currentHealth - (baseChange * dayOffset) + noise
            observations.append(min(max(observedHealth, 0), 100))
        }
        
        observations.append(currentHealth)
        return observations
    }
    
    func getRecommendedWateringDays() -> Int {
        let prediction = getPredictionWithKalman()
        let kalman = KalmanHealthEstimator(initialHealth: self.healthScore)
        
        _ = kalman.forecast(days: 7, analysis_score: self.healthScore)
        let adjustment = kalman.getWateringAdjustment()
        
        let recommendedDays = self.wateringInterval + adjustment
        
        return max(1, min(30, recommendedDays))
    }
    
    var healthTrendEmoji: String {
        let prediction = getPredictionWithKalman()
        switch prediction.trend {
        case .improving: return "Improving"
        case .declining: return "Needs Care"
        case .stable: return "Stable"
        }
    }
}

// MARK: - Urgency Level Enum
enum UrgencyLevel {
    case healthy, soon, urgent, overdue
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .soon: return .yellow
        case .urgent: return .orange
        case .overdue: return .red
        }
    }
}

