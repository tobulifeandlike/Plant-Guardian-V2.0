// Badge.swift 

import Foundation
import SwiftUI

// MARK: - Badge Model
struct Badge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let requirement: BadgeRequirement
    var unlockedDate: Date?
    
    var isUnlocked: Bool {
        unlockedDate != nil
    }
}

// MARK: - Badge Requirements
enum BadgeRequirement: Codable, Equatable {
    case firstPlant                    
    case fivePlants                   
    case tenPlants                     
    case allHealthy                    
    case weekStreak                    
    case monthStreak                  
    case diversity(Int)                
    case healthMaster                  
    case earlyBird                    
    case greenThumb                    
    
    var displayText: String {
        switch self {
        case .firstPlant: return "Add your first plant"
        case .fivePlants: return "Grow your collection to 5 plants"
        case .tenPlants: return "Reach 10 plants"
        case .allHealthy: return "Keep all plants healthy (70%+)"
        case .weekStreak: return "Water on time for 7 consecutive days"
        case .monthStreak: return "Water on time for 30 consecutive days"
        case .diversity(let count): return "Collect \(count) different plant types"
        case .healthMaster: return "Maintain 90%+ average health for 7 days"
        case .earlyBird: return "Water 5 plants before 8:00 AM"
        case .greenThumb: return "Get all plants to 100% health"
        }
    }
}

