// OnboardingView.swift

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var showAnimation = true
    
    // Six core functions
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            icon: "app.connected.to.app.below.fill",
            iconColor: .blue,
            title: "Design Emphasizing Experience and Efficiency",
            subtitle: "Multimodal Interaction for Busy Lives",
            description: "Voice summary provides you organized information to save time for other works, changeable information display like temperature to fit your habit, just a click on the top left;)",
            feature: "Efficient plant care designed for modern lifestyles, Human Interface Guidelines Foundations-Accessibility through hearing.",
            techHighlight: "AVSpeechSynthesizer + Smart Scheduling",
            duration: 5
        ),
        OnboardingPage(
            id: 1,
            icon: "photo",
            iconColor: .green,
            title: "AI Health Analysis",
            subtitle: "Computer Vision for Plant Diagnosis",
            description: "AI analyzes color, texture, and patterns to detect health issues. Distinguishes natural variegation from disease.",
            feature: "85-95% accuracy on variegated plants like Snake Plants. Seen in detailed plant view in 'My Plants' button",
            techHighlight: "Vision Framework + Multi-dimensional RGB Analysis",
            duration: 5
        ),
        OnboardingPage(
            id: 2,
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .mint,
            title: "Kalman Filter Prediction",
            subtitle: "An Estimation Method in Control Applied in Plant Health Prediction",
            description: "Predicts 7-day health trends by analyzing growth velocity and momentum. Adapts to real observations over time.",
            feature: "Originated in control area, Kalman filter provides valuable prediction information to help you dynamically and flexibly schedule watering, fertilizing, etc. Seen in detailed plant view in 'My Plants' button",
            techHighlight: "State Estimation + Uncertainty Quantification",
            duration: 5
        ),
        OnboardingPage(
            id: 3,
            icon: "cube.transparent.fill",
            iconColor: .cyan,
            title: "3D Garden Visualization",
            subtitle: "Emotional Connection Through Immersion",
            description: "Your plants come alive in a 3D garden. Watch them grow, celebrate milestones, and build a virtual sanctuary.",
            feature: "Transforms plant care from chore to joyful ritual.",
            techHighlight: "SceneKit + Dynamic Rendering",
            duration: 5
        ),
        OnboardingPage(
            id: 4,
            icon: "star.circle.fill",
            iconColor: .yellow,
            title: "Achievement System",
            subtitle: "Gamification for Sustained Engagement",
            description: "Unlock badges as you care for your plants. Active/Inactive status reflects current achievements—encouraging consistency.",
            feature: "Designed for long-term habit formation, not just novelty.",
            techHighlight: "Behavioral Design + Progress Tracking",
            duration: 5
        ),
        OnboardingPage(
            id: 5,
            icon: "sparkles",
            iconColor: .teal,
            title: "Built for Real Life",
            subtitle: "Accessible, Private, Open",
            description: "Free forever. No ads, no login, no data collection. Open-source starting from this version. Designed for students, seniors, and everyone in between.",
            feature: "Technology that serves people, not profits.",
            techHighlight: "Privacy-First + Accessibility-Focused",
            duration: 5
        ),
        OnboardingPage(
            id: 6,
            icon: "ellipsis.circle.fill",
            iconColor: .orange,
            title: "More Functions",
            subtitle: "Making the App more powerful and helpful",
            description: "Check the functions being developed or planned to be developed soon.",
            feature: "Swift student challenge version is a good start. This App will be iterated to incorporate more functions, and attract more groups of users",
            techHighlight: "Agile development + Human Interface Guidelines Foundations - Inclusion",
            duration: 5
        ),
        OnboardingPage(
            id: 7,
            icon: "plus.circle.fill",
            iconColor: .green,
            title: "Let's get Started",
            subtitle: "",
            description: "Tap the '+' button on top right to add your first plant",
            feature: "Where you will start;)",
            techHighlight: "Apple Human Interface Guidelines - Creation of a Streamlined, Welcoming start point ",
            duration: 5
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.7, blue: 0.3).opacity(0.3),
                    Color(red: 0.2, green: 0.5, blue: 0.7).opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                progressBar
                
                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        OnboardingPageView(page: page, showAnimation: $showAnimation)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                bottomNavigation
            }
        }
        .onAppear {
            startAutoAdvance()
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentPage ? Color.green : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.horizontal)
            
            Text("Page \(currentPage + 1) of \(pages.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 60)
        .padding(.bottom, 12)
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack(spacing: 20) {
            if currentPage < pages.count - 1 {
                Button {
                    isPresented = false
                } label: {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    isPresented = false
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .fontWeight(.semibold)
                    
                    Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.green)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 40)
    }
    
    // MARK: - Auto Advance
    private func startAutoAdvance() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
            guard currentPage < pages.count - 1 else {
                timer.invalidate()
                return
            }
            
            withAnimation {
                currentPage += 1
            }
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage: Identifiable {
    let id: Int
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
    let feature: String
    let techHighlight: String
    let duration: Int
}

// MARK: - Individual Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var showAnimation: Bool
    
    @State private var iconScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    @State private var featureOffset: CGFloat = 50
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)
                
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(page.iconColor.opacity(0.2))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: page.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(page.iconColor)
                }
                .scaleEffect(iconScale)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        iconScale = 1.0
                    }
                }
                
                // Title & Subtitle
                VStack(spacing: 8) {
                    Text(page.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    
                    Text(page.subtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(textOpacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                        textOpacity = 1.0
                    }
                }
                
                // Description
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)
                    .opacity(textOpacity)
                
                // Feature Highlight
                VStack(spacing: 16) {
                    featureCard(
                        icon: "sparkles",
                        color: .yellow,
                        title: "Key Feature",
                        content: page.feature
                    )
                    
                    featureCard(
                        icon: "gearshape.2.fill",
                        color: .gray,
                        title: "Technical Realization",
                        content: page.techHighlight
                    )
                }
                .offset(y: featureOffset)
                .opacity(textOpacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                        featureOffset = 0
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func featureCard(icon: String, color: Color, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Text(content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Integration in ContentView
extension ContentView {
    var shouldShowOnboarding: Bool {
        !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

