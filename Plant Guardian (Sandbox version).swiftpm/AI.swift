// AI.swift
// 1. RGB judgement
// 2. Distinguish healthy color from unhealthy color
// 3. Variegated plant recognition
// 4. Multi-dimensional grading system

import Vision
import CoreML
import UIKit
import SwiftUI
import CoreImage

//MARK: - Store health analysis result in a structure
struct HealthAnalysisResult {
    let analysisScore: Double        
    let colorHealth: Double          
    let textureHealth: Double        
    let edgeHealth: Double        
    let isVariegated: Bool   
    let colorDistribution: ColorDistribution
    
    struct ColorDistribution {
        let green: Double
        let yellow: Double
        let brown: Double
        let white: Double
    }
}

class PlantHealthAnalyzer {
    // MARK: - Main Analysis Function
    func analyzeHealth(from imageData: Data) async -> HealthAnalysisResult {
        guard !imageData.isEmpty,
              let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            print("Invalid image data")
            return defaultResult()
        }
        guard cgImage.width > 0, cgImage.height > 0,
              cgImage.width < 10000, cgImage.height < 10000 else {
            print("Image dimensions invalid")
            return defaultResult()
        }
        let (colorHealth, colorDist, isVariegated) = analyzeColorHealth(cgImage: cgImage)
        let textureHealth = analyzeTextureHealth(cgImage: cgImage)
        let edgeHealth = analyzeEdgeHealth(cgImage: cgImage)
        // Comprehensive judgement
        let finalScore = (colorHealth * 0.5) + (textureHealth * 0.3) + (edgeHealth * 0.2)
        return HealthAnalysisResult(
            analysisScore: min(max(finalScore, 0), 100),
            colorHealth: colorHealth,
            textureHealth: textureHealth,
            edgeHealth: edgeHealth,
            isVariegated: isVariegated,
            colorDistribution: colorDist
        )
    }
    
    func analyzeHealthSimple(from imageData: Data) async -> Double {
        let result = await analyzeHealth(from: imageData)
        return result.analysisScore
    }
    
    // MARK: - Color Analysis
    private func analyzeColorHealth(cgImage: CGImage) -> (health: Double, distribution:HealthAnalysisResult.ColorDistribution, isVariegated: Bool) {
        let width = cgImage.width
        let height = cgImage.height
        
        guard let pixelData = cgImage.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return (50.0, HealthAnalysisResult.ColorDistribution(green: 0.5, yellow: 0.25, brown: 0.15, white: 0.1), false)
        }
        
        var greenPixels = 0      
        var yellowPixels = 0     
        var brownPixels = 0     
        var whitePixels = 0     
        var totalPixels = 0
        
        let sampleRate = 4
        
        for y in stride(from: 0, to: height, by: sampleRate) {
            for x in stride(from: 0, to: width, by: sampleRate) {
                let pixelIndex = ((width * y) + x) * 4
                
                guard pixelIndex + 2 < CFDataGetLength(pixelData) else {
                    continue
                }
                
                let r = Int(data[pixelIndex])
                let g = Int(data[pixelIndex + 1])
                let b = Int(data[pixelIndex + 2])
                
                if isHealthyGreen(r: r, g: g, b: b) {
                    greenPixels += 1
                } else if isYellow(r: r, g: g, b: b) {
                    yellowPixels += 1
                } else if isBrown(r: r, g: g, b: b) {
                    brownPixels += 1
                } else if isWhiteOrLight(r: r, g: g, b: b) {
                    whitePixels += 1
                }
                
                totalPixels += 1
            }
        }
        
        guard totalPixels > 0 else { 
            return (50.0, HealthAnalysisResult.ColorDistribution(green: 0.5, yellow: 0.25, brown: 0.15, white: 0.1), false)    
        }
        
        let greenRatio = Double(greenPixels) / Double(totalPixels)
        let yellowRatio = Double(yellowPixels) / Double(totalPixels)
        let brownRatio = Double(brownPixels) / Double(totalPixels)
        let whiteRatio = Double(whitePixels) / Double(totalPixels)
        
        print("Color Distribution:")
        print("Green: \(Int(greenRatio * 100))%")
        print("Yellow: \(Int(yellowRatio * 100))%")
        print("Brown: \(Int(brownRatio * 100))%")
        print("White: \(Int(whiteRatio * 100))%")
        
        var score = 50.0
        //Variegated plant recognition
        let isVariegatedPlant = whiteRatio > 0.15 && whiteRatio < 0.5
        
        if isVariegatedPlant {
            print("Variegated plant detected!")
            let healthyColorRatio = greenRatio + whiteRatio
            score += healthyColorRatio * 50
            score -= yellowRatio * 10 
            score -= brownRatio * 25 
            score += 15
        } else {
            score += greenRatio * 45
            score -= yellowRatio * 20
            score -= brownRatio * 30
            if whiteRatio > 0.05 && whiteRatio < 0.15 {
                score += 5
            }
        }
        let distribution = HealthAnalysisResult.ColorDistribution(
            green: greenRatio,
            yellow: yellowRatio,
            brown: brownRatio,
            white: whiteRatio
        )
        return (min(max(score, 0), 100), distribution, isVariegatedPlant)
    }
    
    // MARK: - Color Classification Helpers
    private func isHealthyGreen(r: Int, g: Int, b: Int) -> Bool {
        let isDarkGreen = g > r + 20 &&    
        g > b + 20 &&  
        g > 80 &&        
        g < 230 &&       
        r < 180          
        
        let isLightGreen = g > r + 10 &&   
        g > b + 10 &&   
        g > 70 &&       
        g < 230 &&
        r > 60 &&      
        r < 200        
        return isDarkGreen || isLightGreen
    }
    
    private func isYellow(r: Int, g: Int, b: Int) -> Bool {
        return r > 150 &&
        g > 150 &&
        b < 180 &&
        abs(r - g) < 60
    }
    
    private func isBrown(r: Int, g: Int, b: Int) -> Bool {
        return r > 80 &&
        r < 200 &&
        g > 50 &&
        g < r &&         
        b < g &&         
        (r + g + b) < 500 
    }
    
    private func isWhiteOrLight(r: Int, g: Int, b: Int) -> Bool {
        let isPureWhite = r > 180 && g > 180 && b > 160 &&
        abs(r - g) < 50 && abs(g - b) < 50
        
        let isLightGreen = g > 160 && r > 140 && b > 120 &&
        g > r && (r + g + b) > 450
        
        let isCreamyWhite = r > 170 && g > 170 && b > 140 &&
        r >= g && (g - b) < 50
        
        return isPureWhite || isLightGreen || isCreamyWhite
    }
    
    // MARK: - Texture Analysis
    private func analyzeTextureHealth(cgImage: CGImage) -> Double {
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        guard let edgeFilter = CIFilter(name: "CIEdges") else {
            return 70.0
        }
        edgeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let edgeOutput = edgeFilter.outputImage else {
            return 70.0
        }
        
        let extent = ciImage.extent
        let sampleRect = CGRect(
            x: extent.midX - extent.width * 0.2,
            y: extent.midY - extent.height * 0.2,
            width: extent.width * 0.4,
            height: extent.height * 0.4
        )
        
        guard let cgEdgeImage = context.createCGImage(edgeOutput, from: sampleRect) else {
            return 70.0
        }
        
        let edgeDensity = calculateEdgeDensity(cgEdgeImage)
        
        let textureScore: Double
        if edgeDensity > 0.2 && edgeDensity < 0.6 {
            textureScore = 90.0 
        } else if edgeDensity > 0.1 && edgeDensity < 0.75 {
            textureScore = 75.0 
        } else {
            textureScore = 60.0
        }
        return textureScore
    }
    
    private func calculateEdgeDensity(_ cgImage: CGImage) -> Double {
        let width = cgImage.width
        let height = cgImage.height
        
        guard width > 0, height > 0,
              let pixelData = cgImage.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return 0.5
        }
        
        var whitePixels = 0
        let totalPixels = width * height
        let bytesPerPixel = 4
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = ((width * y) + x) * bytesPerPixel
                
                guard pixelIndex + 2 < CFDataGetLength(pixelData) else {
                    continue
                }
                
                let r = data[pixelIndex]
                
                if r > 200 {
                    whitePixels += 1
                }
            }
        }        
        return Double(whitePixels) / Double(totalPixels)
    }
    
    // MARK: - Edge Health Analysis 
    private func analyzeEdgeHealth(cgImage: CGImage) -> Double {
        let width = cgImage.width
        let height = cgImage.height
        
        guard let pixelData = cgImage.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return 70.0
        }
        
        var edgeGreenPixels = 0
        var edgeBrownPixels = 0
        var edgeSampleCount = 0
        let edgeWidth = width / 10
        let edgeHeight = height / 10
        for y in 0..<edgeHeight {
            for x in stride(from: 0, to: width, by: 4) {
                let pixelIndex = ((width * y) + x) * 4
                guard pixelIndex + 2 < CFDataGetLength(pixelData) else { continue }
                
                let r = Int(data[pixelIndex])
                let g = Int(data[pixelIndex + 1])
                let b = Int(data[pixelIndex + 2])
                
                if isHealthyGreen(r: r, g: g, b: b) {
                    edgeGreenPixels += 1
                } else if isBrown(r: r, g: g, b: b) {
                    edgeBrownPixels += 1
                }
                edgeSampleCount += 1
            }
        }
        
        guard edgeSampleCount > 0 else { return 70.0 }
        
        let greenRatio = Double(edgeGreenPixels) / Double(edgeSampleCount)
        let brownRatio = Double(edgeBrownPixels) / Double(edgeSampleCount)
        
        var edgeScore = 50.0
        edgeScore += greenRatio * 50 
        edgeScore -= brownRatio * 40
        
        return min(max(edgeScore, 0), 100)
    }
    
    // MARK: - Helper Methods
    private func defaultResult() -> HealthAnalysisResult {
        return HealthAnalysisResult(
            analysisScore: 50.0,
            colorHealth: 50.0,
            textureHealth: 50.0,
            edgeHealth: 50.0,
            isVariegated: false,
            colorDistribution: HealthAnalysisResult.ColorDistribution(
                green: 0.5,
                yellow: 0.25,
                brown: 0.15,
                white: 0.1
            )
        )
    }
    
    // MARK: - Extract Dominant Color (for UI)
    func extractDominantColor(from imageData: Data) -> Color {
        guard !imageData.isEmpty,
              let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return .gray
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        guard width > 0, height > 0,
              let pixelData = cgImage.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return .gray
        }
        
        var totalRed = 0
        var totalGreen = 0
        var totalBlue = 0
        var count = 0
        let centerX = width / 2
        let centerY = height / 2
        
        for y in max(0, centerY - 50)..<min(height, centerY + 50) {
            for x in max(0, centerX - 50)..<min(width, centerX + 50) {
                let pixelIndex = ((width * y) + x) * 4
                
                guard pixelIndex + 2 < CFDataGetLength(pixelData) else {
                    continue
                }
                
                totalRed += Int(data[pixelIndex])
                totalGreen += Int(data[pixelIndex + 1])
                totalBlue += Int(data[pixelIndex + 2])
                count += 1
            }
        }
        
        guard count > 0 else { return .gray }
        
        let avgRed = Double(totalRed) / Double(count) / 255.0
        let avgGreen = Double(totalGreen) / Double(count) / 255.0
        let avgBlue = Double(totalBlue) / Double(count) / 255.0
        
        return Color(red: avgRed, green: avgGreen, blue: avgBlue)
    }
}

