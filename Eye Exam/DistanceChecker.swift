import SwiftUI
import ARKit

class DistanceChecker: NSObject, ObservableObject {
    @Published var currentDistance: Float = 0
    @Published var isAtCorrectDistance: Bool = false
    
    private let targetDistance: Float // units in meters
    private let tolerance: Float
    private var arSession: ARSession?
    
    @Published var countdownValue: Int? = nil
    @Published var shouldStartExam: Bool = false
    private var correctDistanceTimer: Timer?
    private var countdownTimer: Timer?
    
    init(targetDistance: Float, tolerance: Float) {
        self.targetDistance = targetDistance
        self.tolerance = tolerance
        super.init()
        setupARSession()
    }
    
    private func setupARSession() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("Face tracking is not supported on this device")
            return
        }
        
        let configuration = ARFaceTrackingConfiguration()
        let session = ARSession()
        session.delegate = self
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.arSession = session
    }
    
    func startDistanceCheck() {
        arSession?.run(ARFaceTrackingConfiguration(), options: [.resetTracking, .removeExistingAnchors])
    }
    
    func stopDistanceCheck() {
        arSession?.pause()
        cancelTimers()
    }
    
    private func startCorrectDistanceTracking() {
           correctDistanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
               self?.startCountdown()
           }
       }
       
       private func startCountdown() {
           countdownValue = 3
           countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
               guard let self = self else { return }
               
               if let current = self.countdownValue {
                   if current > 1 {
                       self.countdownValue = current - 1
                   } else {
                       timer.invalidate()
                       self.countdownValue = nil
                       self.shouldStartExam = true
                   }
               }
           }
       }
       
       private func cancelTimers() {
           correctDistanceTimer?.invalidate()
           correctDistanceTimer = nil
           countdownTimer?.invalidate()
           countdownTimer = nil
           countdownValue = nil
       }
}

extension DistanceChecker: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
               guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
               
               let transform = faceAnchor.transform
               let distance = abs(transform.columns.3.z)
               
               DispatchQueue.main.async {
                   self.currentDistance = distance
                   let isNowAtCorrectDistance = abs(distance - self.targetDistance) <= self.tolerance
                   
                   if isNowAtCorrectDistance != self.isAtCorrectDistance {
                       self.isAtCorrectDistance = isNowAtCorrectDistance
                       if isNowAtCorrectDistance {
                           self.startCorrectDistanceTracking()
                       } else {
                           self.cancelTimers()
                       }
                   }
               }
           }
    
}
