# Plant-Guardian-V2.0

> *AI-powered plant care for people who care about their plants — but are also just really busy.*

## Background

This project started from a simple observation: my roommate's plants kept dying — not from neglect by intention, but from an engineering student's schedule that made "water the plant on Tuesday" feel like a moving target.

The core question became: **can a mobile app reduce the cognitive overhead of plant care to near zero?**

Plant Guardian is my answer. It combines computer vision health analysis, Kalman filter-based growth prediction, and voice-driven notifications into a single, privacy-first app that runs entirely on-device — no cloud, no subscription, no data collection.


## Target Users

| User Group | Pain Point Addressed |
|---|---|
| University students & young professionals | Irregular schedules, forgetting watering cycles |
| Seniors with many plants | Simple UI, voice reminders, no technical barrier |
| Plant beginners | Guided care tips, AI health feedback with no expertise required |
| Remote workers / home office enthusiasts | Build a green workspace without becoming a horticulturist |

---

## Core Features

### 🔬 AI Health Analysis (Vision Framework)
Analyzes plant photos through a multi-dimensional RGB pipeline:
- **Color health scoring** — distinguishes healthy green from yellowing or browning
- **Variegated plant recognition** — correctly identifies white/cream patterns as natural (not disease) in plants like Pothos and Snake Plants
- **Texture & edge analysis** — detects leaf surface degradation using CIEdges filter
- **Accuracy**: 85–95% on common houseplants

The scoring model:
```
Final Score = (Color Health × 0.5) + (Texture Health × 0.3) + (Edge Health × 0.2)
```

### 📈 Kalman Filter Health Prediction
Predicts 7-day plant health trajectory using a 2-state Kalman filter:

```
State vector: x = [health, health_velocity]ᵀ
State transition: x(k) = A·x(k-1) + B·u(k) + w(k)
Observation: y(k) = C·x(k) + v(k)
```

The filter recursively updates its estimate from historical health observations, producing a confidence-weighted forecast with trend classification (Improving / Stable / Declining). Watering schedule adjustments are derived from the predicted health change.

> Inspired by Kalman filter applications in agricultural sensor fusion and MATLAB-based signal estimation techniques.

### 🔊 Voice Notification System (AVSpeechSynthesizer)
- Daily audio summary of all plant care tasks
- Priority-ranked announcements: urgent watering → fertilizing → health alerts
- Celebration messages on badge unlocks and watering completions
- System sound effects (AudioServicesPlaySystemSound) for full iPad compatibility

### 🌳 3D Garden Visualization (SceneKit)
- Real-time 3D scene renders all your plants spatially
- Dynamic position layout with boundary-clamped randomization: O(n) placement
- Transparent background composited over SwiftUI gradient layers
- USDZ model support for future custom plant species

### 🏆 Achievement System
8 unlockable badges with active/inactive state tracking:

| Badge | Requirement |
|---|---|
| First Sprout | Add first plant |
| Growing Garden | 5 plants |
| Plant Collector | 10 plants |
| Variety Lover | 3 different species |
| Botanical Enthusiast | 5 different species |
| Health Guardian | All plants > 70% health |
| Green Thumb Master | All plants at 100% |
| Consistent Caretaker | 7-day watering streak |

Badge state is persisted via `UserDefaults` with JSON encoding. Active/Inactive distinction reflects whether the achievement condition is *currently maintained*, not just historically achieved — encouraging consistent behavior rather than one-time unlocks.

### 📋 Smart Task Management
- Watering and fertilizing schedules with overdue detection
- Urgency levels: Healthy → Soon → Urgent → Overdue
- Batch plant selection and deletion
- Full-text search and multi-criteria sorting

### 🌤️ Environment Display
- Simulated temperature & humidity display (mock sensor layer)
- Toggleable °C / °F with a single tap
- Architecture is IoT-ready: replace `MockWeatherManager` with a real weather API or CoreLocation integration

---

## Architecture

**Pattern**: MVVM with dependency injection  
**Persistence**: SwiftData (`@Model` + `ModelContainer`)  
**UI**: SwiftUI with NavigationStack  
**Audio**: AVFoundation + AudioToolbox  
**Vision**: Core Image + Vision framework  
**3D**: SceneKit  
**NLP**: NaturalLanguage framework (fuzzy plant name matching via Levenshtein distance)

```
PlantGuardianApp
├── ContentView              # Main dashboard, 4-layer ZStack composition
├── MyPlantsView             # Plant list with search, sort, batch operations
│   └── PlantDetailView      # Per-plant health analysis + Kalman chart
├── GardenView               # SceneKit 3D visualization
├── BadgeSystem              # Achievement manager + unlock popup queue
├── AI.swift                 # RGB health analyzer
├── KalmanHealthEstimator    # Kalman filter prediction engine
├── VoiceNotificationManager # TTS + sound effect system
├── WeatherManager           # Environment data layer (mock / extensible)
├── PlantDatabase            # Local knowledge base + NLP fuzzy matcher
└── OnboardingView           # 7-page interactive introduction
```

---

## Design Philosophy

**1. Multimodal by default.**  
Information is delivered visually *and* through voice. A busy person who picks up their iPad while cooking should still know which plants need water.

**2. Privacy-first, always.**  
All computation runs on-device. No account required. No analytics. No ads. No cloud dependency.

**3. Accessible to everyone.**  
Sound effects replace haptic feedback for iPad compatibility. Font sizes, contrast ratios, and interaction targets follow Apple Human Interface Guidelines throughout.

**4. Honest about what it knows.**  
The Kalman filter's confidence score is surfaced to the user. The health analyzer returns a `defaultResult()` gracefully on bad input rather than fabricating confidence.

**5. Designed for future extension.**  
`MockWeatherManager` is a drop-in replacement target for a real WeatherKit integration. `PlantDatabase` uses a protocol-compatible local array ready for a remote fetch layer. Badge requirements are enum-driven, making new achievements a 3-line addition.

---

## Roadmap

- [ ] WeatherKit integration for environment-adjusted watering schedules  
- [ ] ARKit garden preview — visualize plants in your actual room before buying  
- [ ] Apple Watch companion app for quick watering confirmations  
- [ ] iCloud sync across devices  
- [ ] Home Screen widgets  
- [ ] Community plant photo sharing  
- [ ] IoT sensor bridge (soil moisture, light intensity)

---

## Getting Started

**Requirements**
- iPad with iPadOS 17.0+
- Xcode 15+ or Swift Playgrounds 4.4+

**Run in Swift Playgrounds**
1. Clone this repository
2. Open `PlantGuardian.swiftpm` in Swift Playgrounds on iPad
3. Tap Run

**Run in Xcode**
1. Clone this repository
2. Open the `.swiftpm` package in Xcode 15+
3. Select an iPad simulator or connected device
4. Build and run

> No third-party dependencies. Pure Apple frameworks only.

---

## License

MIT License — see [LICENSE](LICENSE) for full terms.

You are free to use, modify, and distribute this code for personal or commercial purposes. Attribution appreciated but not required.

---

## Acknowledgements

- Kalman filter theory adapted from classical control systems literature (Welch & Bishop, 1995) and agricultural sensor fusion research
- Apple Human Interface Guidelines — the primary design reference throughout
- Swift Student Challenge 2026 — the deadline that made this ship

---

*Built with SwiftUI · SceneKit · Vision · AVFoundation · SwiftData*  
*Developed for Swift Student Challenge 2026*
