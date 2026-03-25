// MockWeatherManager.swift
// Simulate Weather Information Display in Swift Playground Environment

import Foundation
import SwiftUI

@MainActor
class MockWeatherManager: ObservableObject {
    static let shared = MockWeatherManager()
    
    @Published var temperature: Double = 22.5  // Default Temperature Display (Celsius）
    @Published var humidity: Double = 65.0     // Default Humidity（Percentage）
    
    private init() {
        // Simulate Real-Time Variation（Optional）
        startSimulation()
    }
    
    // Simulate the Variation of Weather Data
    private func startSimulation() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Fluctuating in 20-28 Degree Celsius
            self.temperature = Double.random(in: 20.0...28.0)
            
            // Fluctuating in 50-80%
            self.humidity = Double.random(in: 50.0...80.0)
        }
    }
    
    // Formatting Temperature（C/F）
    func formattedTemperature(useFahrenheit: Bool) -> String {
        if useFahrenheit {
            let fahrenheit = temperature * 9/5 + 32
            return String(format: "%.1f°F", fahrenheit)
        } else {
            return String(format: "%.1f°C", temperature)
        }
    }
    
    // Formatting Humidity
    func formattedHumidity() -> String {
        return String(format: "%.0f%%", humidity)
    }
    
    // Set Temperature (for Demo Showcase)
    func setTemperature(_ temp: Double) {
        temperature = temp
    }
    
    // Set Humidity
    func setHumidity(_ hum: Double) {
        humidity = hum
    }
    
    // Give Different Weather Cases
    func simulateWeather(scenario: WeatherScenario) {
        switch scenario {
        case .sunny:
            temperature = 28.0
            humidity = 45.0
        case .rainy:
            temperature = 18.0
            humidity = 85.0
        case .cloudy:
            temperature = 22.0
            humidity = 65.0
        case .hot:
            temperature = 35.0
            humidity = 55.0
        case .cold:
            temperature = 10.0
            humidity = 60.0
        }
    }
}

// List Weather Cases
enum WeatherScenario {
    case sunny   
    case rainy   
    case cloudy  
    case hot     
    case cold 
}
