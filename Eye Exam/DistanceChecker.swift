import SwiftUI
import ARKit

class DistanceChecker: NSObject, ObservableObject {
    @Published var currentDistance: Float = 0
    @Published var isAtCorrectDistance: Bool = false
    
    private let targetDistance: Float // units in meters
    private let tolerance: Float
    private var arSession: ARSession?
    
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
    }
}

// ARSession delegate to receive updates
extension DistanceChecker: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        
        // Get the distance from the camera to the face
        let transform = faceAnchor.transform
        let distance = abs(transform.columns.3.z)
        
        DispatchQueue.main.async {
            self.currentDistance = distance
            self.isAtCorrectDistance = abs(distance - self.targetDistance) <= self.tolerance
        }
    }
}
