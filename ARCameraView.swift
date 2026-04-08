//
//  ARCameraView.swift
//  ARHUD
//
//  ARKit camera view with world tracking
//

import SwiftUI
import ARKit
import SceneKit

struct ARCameraViewRepresentable: UIViewRepresentable {
    @ObservedObject var hudSettings: HUDSettings
    @ObservedObject var locationManager: LocationDataManager
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        arView.session.run(configuration)
        
        // Set delegate for camera updates
        arView.session.delegate = context.coordinator
        
        // Configure scene
        arView.scene = SCNScene()
        arView.autoenablesDefaultLighting = false
        arView.showsStatistics = false
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Update when settings change
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(locationManager: locationManager)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        let locationManager: LocationDataManager
        
        init(locationManager: LocationDataManager) {
            self.locationManager = locationManager
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Extract camera transform
            let cameraTransform = frame.camera.transform
            
            // Extract pitch (rotation around X-axis) from the transform matrix
            // The camera's "forward" direction is -Z axis in camera space
            // We need to find the angle between forward vector and horizontal plane
            let cameraDirection = simd_float3(
                cameraTransform.columns.2.x,
                cameraTransform.columns.2.y,
                cameraTransform.columns.2.z
            )
            
            // Calculate pitch angle (rotation around X-axis)
            // Pitch is the angle from horizontal plane
            let pitch = asin(-cameraDirection.y)
            
            // Update location manager with pitch
            DispatchQueue.main.async {
                self.locationManager.cameraPitch = Double(pitch)
            }
        }
    }
}
