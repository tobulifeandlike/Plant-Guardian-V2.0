// VoiceNotificationManager.swift

import Foundation
import AVFoundation
import SwiftData
import AudioToolbox  

class VoiceNotificationManager: ObservableObject {
    static let shared = VoiceNotificationManager()
    
    // MARK: - Audio Components
    private let synthesizer = AVSpeechSynthesizer()
    
    // MARK: - State Management
    @Published var isPlaying = false
    @Published var lastAnnouncementText: String = ""  
    
    private var reminderQueue: [String] = []
    private var currentUtterance: AVSpeechUtterance?
    
    private init() {
        configureAudioSession()
        setupSynthesizerDelegate()
    }
    
    // MARK: - Audio Session Configuration
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Audio session configuration failed: \(error)")
        }
    }
    
    // MARK: - Synthesizer Delegate Setup
    private func setupSynthesizerDelegate() {
        synthesizer.delegate = SpeechDelegate.shared
        SpeechDelegate.shared.onFinish = { [weak self] in
            self?.speechFinished()
        }
    }
    
    @objc private func speechFinished() {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.playNextReminder()
        }
    }
    
    // MARK: - Core Check & Announce Function
    func checkAndAnnounce(plants: [Plant]) {
        reminderQueue.removeAll()
        lastAnnouncementText = ""
        let plantsNeedingWater = plants.filter {
            Calendar.current.isDateInToday($0.nextWateringDate) ||
            $0.nextWateringDate < Date()
        }
        let plantsNeedingFertilizer = plants.filter {
            Calendar.current.isDateInToday($0.nextFertilizingDate) ||
            $0.nextFertilizingDate < Date()
        }
        let unhealthyPlants = plants.filter { $0.healthScore < 50 }
        let plantsNeedingAttention = plants.filter { 
            $0.healthScore >= 50 && $0.healthScore < 70 
        }
        //Construct voice message 
        var allMessages: [String] = []
        
        if !plantsNeedingWater.isEmpty {
            let message = generateWateringMessage(plants: plantsNeedingWater)
            reminderQueue.append(message)
            allMessages.append(message)
        }
        
        if !plantsNeedingFertilizer.isEmpty {
            let message = "\(plantsNeedingFertilizer.count) plant\(plantsNeedingFertilizer.count > 1 ? "s" : "") need\(plantsNeedingFertilizer.count == 1 ? "s" : "") fertilizing"
            reminderQueue.append(message)
            allMessages.append(message)
        }
        
        if !unhealthyPlants.isEmpty {
            let plantNames = unhealthyPlants.map { $0.name }.joined(separator: ", ")
            let message = "Alert: \(plantNames) \(unhealthyPlants.count > 1 ? "are" : "is") unhealthy. Health score below 50."
            reminderQueue.append(message)
            allMessages.append(message)
        }
        
        if !plantsNeedingAttention.isEmpty {
            let message = "Attention: \(plantsNeedingAttention.count) plant\(plantsNeedingAttention.count > 1 ? "s" : "") need\(plantsNeedingAttention.count == 1 ? "s" : "") extra care"
            reminderQueue.append(message)
            allMessages.append(message)
        }
        if !allMessages.isEmpty {
            lastAnnouncementText = allMessages.joined(separator: ". ")
            playNextReminder()
            playSoundEffect(.notification)
        } else {
            let successMessage = "Great job! All plants are healthy and well-watered!"
            lastAnnouncementText = successMessage
            speak(successMessage)
            playSoundEffect(.success)
        }
    }
    
    // MARK: - NEW: Announce Immediate (for Badge System)
    /// - Parameter message
    func announceImmediate(_ message: String) {
        speak(message)
    }
    
    // MARK: - Replay Last Announcement
    func replayLastAnnouncement() {
        guard !lastAnnouncementText.isEmpty else {
            speak("No previous announcements to replay")
            return
        }
        
        stopSpeaking()
        speak(lastAnnouncementText)
        playSoundEffect(.replay)
    }
    
    // MARK: - Watering Message Generation
    private func generateWateringMessage(plants: [Plant]) -> String {
        if plants.count == 1 {
            return "\(plants[0].name) needs watering"
        } else if plants.count <= 3 {
            let names = plants.map { $0.name }.joined(separator: ", ")
            return "\(names) need watering"
        } else {
            return "\(plants.count) plants need watering"
        }
    }
    
    // MARK: - Queue Playback Logic
    private func playNextReminder() {
        guard !isPlaying, !reminderQueue.isEmpty else { return }
        
        let message = reminderQueue.removeFirst()
        speak(message)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isPlaying = false
            self?.playNextReminder()
        }
    }
    
    // MARK: - TTS Core Method
    private func speak(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        utterance.preUtteranceDelay = 0.2
        
        currentUtterance = utterance
        isPlaying = true
        synthesizer.speak(utterance)
        
        print("Voice: \(text)")
    }
    
    // MARK: - Sound Effects (iPad Compatible)
    enum SoundEffect {
        case success       
        case notification  
        case warning      
        case replay        
        case waterPlant    
        case unlockBadge   
    }
    
    /// - Parameter effect
    func playSoundEffect(_ effect: SoundEffect) {
        let systemSoundID: SystemSoundID
        
        switch effect {
        case .success:
            systemSoundID = 1054  // Tink
        case .notification:
            systemSoundID = 1315  // Alert
        case .warning:
            systemSoundID = 1053  // Tock
        case .replay:
            systemSoundID = 1104  // JBL_Begin
        case .waterPlant:
            systemSoundID = 1057  // Bloom
        case .unlockBadge:
            systemSoundID = 1107  // Fanfare
        }
        
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    // MARK: - Stop Speaking
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        reminderQueue.removeAll()
        isPlaying = false
    }
    
    // MARK: - Scheduled Daily Reminder
    func scheduleDaily(hour: Int, minute: Int, plants: [Plant]) {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        guard let targetTime = calendar.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        ) else {
            print("Failed to schedule daily reminder")
            return
        }
        
        let timeInterval = targetTime.timeIntervalSinceNow
        
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.checkAndAnnounce(plants: plants)
            self?.scheduleDaily(hour: hour, minute: minute, plants: plants)
        }
        
        print("Daily reminder scheduled for \(hour):\(String(format: "%02d", minute))")
    }
    
    // MARK: - Celebration Messages
    func celebrateWatering(plantName: String) {
        let messages = [
            "Great! \(plantName) has been watered.",
            "Well done! \(plantName) is happy now.",
            "\(plantName) says thank you!"
        ]
        let message = messages.randomElement() ?? messages[0]
        speak(message)
        playSoundEffect(.waterPlant)
    }
    
    func celebrateBadgeUnlock(badgeName: String) {
        speak("Congratulations! You unlocked \(badgeName)!")
        playSoundEffect(.unlockBadge)
    }
    
    // MARK: - Health Status Announcement
    func announceHealthStatus(plant: Plant) {
        let healthScore = Int(plant.healthScore)
        let message: String
        
        switch healthScore {
        case 90...100:
            message = "\(plant.name) is in excellent health with a score of \(healthScore)"
            playSoundEffect(.success)
        case 70..<90:
            message = "\(plant.name) is doing well with a score of \(healthScore)"
        case 50..<70:
            message = "\(plant.name) needs some care. Health score is \(healthScore)"
            playSoundEffect(.notification)
        default:
            message = "Warning! \(plant.name) is unhealthy. Please check immediately."
            playSoundEffect(.warning)
        }
        
        speak(message)
    }
    
    // MARK: - Morning Greeting
    func morningGreeting(plantCount: Int) {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        
        if hour < 12 {
            greeting = "Good morning!"
        } else if hour < 18 {
            greeting = "Good afternoon!"
        } else {
            greeting = "Good evening!"
        }
        
        let fullGreeting = "\(greeting) You have \(plantCount) plant\(plantCount == 1 ? "" : "s") in your garden."
        speak(fullGreeting)
    }
}

// MARK: - Speech Delegate Helper
class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechDelegate()
    var onFinish: (() -> Void)?
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }
}

