// SceneKitGardenView.swift
// Function: Renders a 3D cartoon garden with imported USDZ models (starting with summertree.usdz). Correlation: Adjusts plant spatial positions for better layout as per prompt; focuses on vivid, professional plants. Alternative: Use grid positioning for structured gardens (O(sqrt(n)) calculation).

import SwiftUI
import SceneKit
import CoreImage  // For noise texture if needed (built-in)


// MARK: - SwiftUI Wrapper
// Function: Wraps SCNView in SwiftUI for UI integration. Correlation: Frames the garden view with adjustable positions; O(1) render. Alternative: Add .gesture for drag repositioning if interactive.
struct SceneKitGardenView: View {
    let plants: [Plant]
    
    var body: some View {
        ZStack {
            SceneKitWrapper(plants: plants)
                .frame(height: 250)
            if plants.isEmpty {
                emptyStateOverlay
            }
            
        }
    }
    // MARK: - （SwiftUI Layer）
    private var emptyStateOverlay: some View {
        VStack {
            Spacer()
            
            Text("Tap '+' to add your plant;)")
                .font(.system(size: 14, weight: .bold, design: .rounded))  // rounded font design
                .foregroundColor(Color(white: 0.2))  // 深灰色
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            
            Spacer()
        }
    }
}

// MARK: - UIKit Static Garden
struct SceneKitWrapper: UIViewRepresentable {
    let plants: [Plant]
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        
        // Transparent Background
        scnView.backgroundColor = .clear
        
        // Stop All Interactions 
        scnView.allowsCameraControl = false
        scnView.isUserInteractionEnabled = false
        
        // Auto Lightning
        scnView.autoenablesDefaultLighting = true
        
        // Anti-aliasing
        scnView.antialiasingMode = .multisampling4X
        
        // Set the Scene
        scnView.scene = createGardenScene()
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update the Scene
        uiView.scene = createGardenScene()
    }
    
    // MARK: - Create the 3D Scene
    private func createGardenScene() -> SCNScene {
        let scene = SCNScene()
        
        // Transparent Background
        scene.background.contents = UIColor.clear
        
        // Set Camera
        setupCamera(in: scene)
        
        // Add Light Source
        setupLighting(in: scene)
        
        // Create the Ground
        createGround(in: scene)
        
        // Add the Plant
        if !plants.isEmpty {
            addPlants(to: scene)
        }
        
        return scene
    }
    
    // MARK: - Camera Configureation
    private func setupCamera(in scene: SCNScene) {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        
        cameraNode.position = SCNVector3(x: 8, y: 14, z: 13)
        cameraNode.eulerAngles = SCNVector3(x: -Float.pi/5.5, y: Float.pi/6, z: 0)
        
        cameraNode.camera?.fieldOfView = 50
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        let center = calculateGardenCenter(in: scene)
        let centerNode = SCNNode()
        centerNode.position = center
        scene.rootNode.addChildNode(cameraNode)
        
        let lookAtConstraint = SCNLookAtConstraint(target: centerNode)
        lookAtConstraint.isGimbalLockEnabled = false  // Avoid lock for natural rotation
        cameraNode.constraints = [lookAtConstraint]
        scene.rootNode.addChildNode(cameraNode)
    }
    
    // Compute the Center of Camera as Reference to Calibrate the Space Configuration
    private func calculateGardenCenter(in scene: SCNScene) -> SCNVector3 {
        var totalX: Float = 0, totalY: Float = 0, totalZ: Float = 0
        let plantNodes = scene.rootNode.childNodes { node, _ in node.geometry != nil } 
        let count = Float(plantNodes.count)
        if count == 0 { return SCNVector3(0, 0, 0) }
        
        for node in plantNodes {
            totalX += node.position.x
            totalY += node.position.y
            totalZ += node.position.z
        }
        
        return SCNVector3(totalX / count, totalY / count, totalZ / count)
    }
    
    // MARK: - Light Setup
    private func setupLighting(in scene: SCNScene) {
        //Key Light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.position = SCNVector3(x: 5, y: 15, z: 8)
        directionalLight.light?.intensity = 1000
        directionalLight.light?.castsShadow = true
        scene.rootNode.addChildNode(directionalLight)
        
        //Ambient Light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        scene.rootNode.addChildNode(ambientLight)
        
        //Rim Light
        let rimLight = SCNNode()
        rimLight.light = SCNLight()
        rimLight.light?.type = .ambient
        rimLight.position = SCNVector3(x: -8, y: 8, z: -5)
        rimLight.light?.intensity = 300
        scene.rootNode.addChildNode(rimLight)
    }
    
    // MARK: - Create Garden Soil
    private func createGround(in scene: SCNScene) {
        let groundGeometry = SCNBox(width: 13, height: 0.35, length: 13, chamferRadius: 0.085)
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = UIColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 0.8)
        
        let noiseFilter = CIFilter(name: "CIRandomGenerator")
        let noiseImage = noiseFilter?.outputImage?.cropped(to: CGRect(x: 0, y: 0, width: 512, height: 512))
        groundMaterial.normal.contents = noiseImage
        groundMaterial.normal.intensity = 0.5
        
        groundGeometry.materials = [groundMaterial]
        let groundNode = SCNNode(geometry: groundGeometry)
        groundNode.position = SCNVector3(0, -0.2, 0)
        scene.rootNode.addChildNode(groundNode)
    }
    
    // MARK: - Add Plants
    private func addPlants(to scene: SCNScene) {
        let spacing: Float = 2.0
        for (index, plant) in plants.enumerated() {
            let plantGroup = createPlantNode(for: plant)
            let adjustedPosition = positionAdjustment(for: index, plantCount: plants.count, spacing: spacing)
            plantGroup.position = adjustedPosition
            scene.rootNode.addChildNode(plantGroup)
        }
    }
    
    // MARK: - Position Adjustment
    private func positionAdjustment(for index: Int, plantCount: Int, spacing: Float) -> SCNVector3 {
        let baseX = Float(index) * spacing - Float(plantCount - 1) * spacing / 2
        let randomOffsetX = Float(arc4random_uniform(3)) - 1.5  
        let randomOffsetZ = Float(arc4random_uniform(3)) - 1.5 
        
        // Boundary clamp to stay within soil (width 15)
        let clampedX = max(min(baseX + randomOffsetX, 7.5), -7.5)  // O(1) clamp
        let clampedZ = max(min(randomOffsetZ, 7.5), -7.5)
        
        return SCNVector3(x: clampedX, y: 0, z: clampedZ)
    }
    
    // MARK: - Create Single Plant Node 
    private func createPlantNode(for plant: Plant) -> SCNNode {
        let plantGroup = SCNNode()
        
        // Load usdz model (summertree.usdz as default)
        let modelName = "TreeSummer" 
        if let url = Bundle.main.url(forResource: modelName, withExtension: "usdz") {
            do {
                let modelScene = try SCNScene(url: url, options: nil)
                let modelNode = modelScene.rootNode.clone()
                modelNode.scale = SCNVector3(0.15, 0.15, 0.15)  // Smaller scale
                modelNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
                plantGroup.addChildNode(modelNode)
            } catch {
                print("Model load error: \(error)")
            }
        }
        return plantGroup
    }
}

// Helper extension for color
extension UIColor {
    func darker(by percentage: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: max(r - percentage/100, 0), green: max(g - percentage/100, 0), blue: max(b - percentage/100, 0), alpha: a)
    }
}
