// KalmanHealthEstimator.swift
// Function: Implements Kalman Filter for plant health prediction based on historical data

import Foundation
import SwiftUI  
import Accelerate 

// MARK: - Kalman Filter Theory
/*
 
 State Space reporesentation：x(k) = A*x(k-1) + w(k)  (w: process noise); y(k) = C*x(k) + v(k)    (v: measurement noise)
 
 Recursive updating：
 1. Initial guess: P(k-1|k-1) and give first prediction x_pred = A*x
 2. Compute P(k|k-1)：P = A*P*A' + M
 3. Kalman gain：K = P*C' / (C*P*C' + R)
 4. Update the state：x_est = x_pred + K*(y - C*x_pred)
 5. Update covariance matrix：P = (I - K*C)*P
 
 One demo state space model for plant health prediction：
 - state x = [current health, health rate of change]'
 - observation y = photo uploaded
 - prediction：estimate future plant health in future 3-7 days
 */

// MARK: - Health Prediction Result
struct HealthPrediction {
    let currentEstimate: Double      // current health assessment (0-100)
    let futureEstimates: [Double]    // prediction 
    let trend: HealthTrend           
    let confidence: Double           // confidence
    let daysForecast: Int
    let dailyPredictions: [Double]
    
    var predicted_score: Double{
        return futureEstimates.last ?? currentEstimate
    }
}

public enum HealthTrend {
    case improving    
    case stable       
    case declining    
    
    var color: String {
        switch self {
        case .improving: return "green"
        case .stable: return "yellow"
        case .declining: return "red"
        }
    }
    
    public var swiftUIColor: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }
    
    public var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
    
    public var description: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Needs Care"
        }
    }
}

// MARK: - Kalman Filter Implementation
class KalmanHealthEstimator {
    
    // MARK: - State Variables 
    private var x_est: [Double]      
    private var P: [[Double]]        
    
    // MARK: - Model Parameters
    // A demo model used for function display
    private let A: [[Double]] = [         
        [0.99, 0.95],  
        [0.0, 0.95]  
    ]
    private let B: [[Double]] = [
        [0.02],
        [0.01]
    ]
    
    private let Q: [[Double]] = [
        [0.0005,0.0],
        [0.0, 0.000003]
    ]
    
    private let R: Double = 0.008
    
    private let C: [Double] = [1.0, 0.0]
    
    private(set) var predicted_score: Double = 0.0
    private(set) var recommended_watering_adjustment:Int = 0
    // MARK: - Initialization
    init(initialHealth: Double) {
        self.x_est = [initialHealth, 0.0]
        
        self.P = [
            [0.05, 0.0],
            [0.0, 0.025]
        ]
    }
    
    // MARK: - Core Update Function 
    private func predict(wateringAmount: Double = 0.0) {
        // x' = A*x + B*u
        let Ax = matrixVectorMultiply(A, x_est)
        let Bu = matrixVectorMultiply(B, [wateringAmount])
        x_est = vectorAdd(Ax, Bu)
        // P' = A*P*A' + Q
        let AP = matrixMultiply(A, P)
        let APAT = matrixMultiply(AP, transpose(A))
        P = matrixAdd(APAT, Q)
        x_est[0] = max(0, min(100, x_est[0]))
    }
    
    // MARK: - Update Step 
    func update(observation: Double) {
        predict(wateringAmount: 0.35)
        //Kalman Gain
        let PC = matrixVectorMultiply(P, C)
        let CPC = dotProduct(C, PC)
        let denominator = CPC + R
        let K = PC.map { $0 / denominator }
        //Compensation
        let innovation = observation - dotProduct(C, x_est)
        //State update x = x + K*innovation
        x_est = vectorAdd(x_est, K.map { $0 * innovation })
        //Covariance update: P = (I - K*C)*P
        let KC = outerProduct(K, C)
        let I_KC = matrixSubtract(identityMatrix(2), KC)
        P = matrixMultiply(I_KC, P)
        x_est[0] = max(0, min(100, x_est[0]))
    }
    
    // MARK: - Prediction Function 
    func forecast(days: Int = 7, wateringSchedule: [Int: Double] = [:],
                  analysis_score: Double) -> HealthPrediction {
        let originalState = x_est
        let originalP = P
        var predictions: [Double] = [analysis_score]
        for day in 1...days {
            let wateringAmount = wateringSchedule[day] ?? 0.03
            predict(wateringAmount: wateringAmount)
            predictions.append(x_est[0])
        }
        predicted_score = predictions[days]
        let healthChange = predicted_score - analysis_score
        recommended_watering_adjustment = calculateWateringAdjustment(healthChange: healthChange)
        
        x_est = originalState
        P = originalP
        
        let trend = determineTrend(healthChange: healthChange)
        let uncertainty = P[0][0]+P[1][1]
        let confidence = max(0,min(1,1.0/(1.0+uncertainty/10.0)))
        return HealthPrediction(
            currentEstimate: analysis_score,
            futureEstimates: Array(predictions[1...]),  
            trend: trend,
            confidence: confidence,
            daysForecast: days,
            dailyPredictions: predictions 
        )
    }
    
    private func calculateWateringAdjustment(healthChange: Double) -> Int {
        if healthChange < -5 {
            //Decreasing health
            return -2
        } else if healthChange > 5 {
            // Improving health
            return +3
        } else {
            // Stable
            return 0
        }
    }
    
    // MARK: - Trend Analysis
    private func determineTrend(healthChange: Double) -> HealthTrend {
        if healthChange > 5 { return .improving }     
        if healthChange < -5 { return .declining }    
        return .stable
    }
    
    func getWateringAdjustment() -> Int {
        return recommended_watering_adjustment
    }
    
    private func matrixVectorMultiply(_ matrix: [[Double]], _ vector: [Double]) -> [Double] {
        if matrix[0].count == 1 {
            return [
                matrix[0][0] * vector[0],
                matrix[1][0] * vector[0]
            ]
        } else {
            return [
                matrix[0][0] * vector[0] + matrix[0][1] * vector[1],
                matrix[1][0] * vector[0] + matrix[1][1] * vector[1]
            ]
        }
    }
    
    private func matrixMultiply(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
        return [
            [
                A[0][0]*B[0][0] + A[0][1]*B[1][0],
                A[0][0]*B[0][1] + A[0][1]*B[1][1]
            ],
            [
                A[1][0]*B[0][0] + A[1][1]*B[1][0],
                A[1][0]*B[0][1] + A[1][1]*B[1][1]
            ]
        ]
    }
    
    private func transpose(_ matrix: [[Double]]) -> [[Double]] {
        return [
            [matrix[0][0], matrix[1][0]],
            [matrix[0][1], matrix[1][1]]
        ]
    }
    
    private func matrixAdd(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
        return [
            [A[0][0] + B[0][0], A[0][1] + B[0][1]],
            [A[1][0] + B[1][0], A[1][1] + B[1][1]]
        ]
    }
    
    private func matrixSubtract(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
        return [
            [A[0][0] - B[0][0], A[0][1] - B[0][1]],
            [A[1][0] - B[1][0], A[1][1] - B[1][1]]
        ]
    }
    
    private func vectorAdd(_ a: [Double], _ b: [Double]) -> [Double] {
        return zip(a, b).map(+)
    }
    
    private func dotProduct(_ a: [Double], _ b: [Double]) -> Double {
        return zip(a, b).map(*).reduce(0, +)
    }
    
    private func outerProduct(_ a: [Double], _ b: [Double]) -> [[Double]] {
        return [
            [a[0] * b[0], a[0] * b[1]],
            [a[1] * b[0], a[1] * b[1]]
        ]
    }
    
    private func identityMatrix(_ size: Int) -> [[Double]] {
        var matrix = Array(repeating: Array(repeating: 0.0, count: size), count: size)
        for i in 0..<size {
            matrix[i][i] = 1.0
        }
        return matrix
    }
}

extension Plant{
    func getFuturePrediction() -> HealthPrediction {
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
}

