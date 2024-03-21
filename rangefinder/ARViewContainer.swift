//
//  ARViewContainer.swift
//  rangefinder
//
//  Created by skyjerry on 2024/3/19.
//

import SwiftUI
import ARKit

struct ARViewContainer: UIViewRepresentable {
    @Binding var distance: String
    @Binding var screenCenterY: CGFloat  // 添加这一行
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        context.coordinator.arView = arView
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.sceneReconstruction = .mesh
        configuration.frameSemantics = .sceneDepth
        arView.session.run(configuration)
        
        arView.delegate = context.coordinator
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARViewContainer
        var arView: ARSCNView?
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard let arView = self.arView else { return }
            let screenCenterX = arView.bounds.midX
            let screenCenterY = arView.bounds.midY
            let screenCenter = CGPoint(x: screenCenterX, y: screenCenterY)
            parent.screenCenterY = screenCenterY  // 将Y坐标传递给ContentView

            guard let currentFrame = arView.session.currentFrame else {
                self.parent.distance = "No distance detected."
                return
            }
            
            // 检查是否支持深度
            guard let depthData = currentFrame.sceneDepth else {
                self.parent.distance = "Depth not available."
                return
            }
            
            let depthMap = depthData.depthMap
            
            // 获取深度图像的分辨率
            let width = CVPixelBufferGetWidth(depthMap)
            let height = CVPixelBufferGetHeight(depthMap)
            
            // 将屏幕坐标转换为深度图像坐标
            let depthPoint = CGPoint(
                x: screenCenter.x / arView.bounds.width * CGFloat(width),
                y: screenCenter.y / arView.bounds.height * CGFloat(height)
            )
            
            // 获取该点的深度值
            CVPixelBufferLockBaseAddress(depthMap, .readOnly)
            let rowData = CVPixelBufferGetBaseAddress(depthMap)! + Int(depthPoint.y) * CVPixelBufferGetBytesPerRow(depthMap)
            let depthPointer = rowData.assumingMemoryBound(to: Float32.self)
            let depth = depthPointer[Int(depthPoint.x)]
            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
            
            if depth.isNaN || depth > 5.0 {
                self.parent.distance = "Out of range"
            } else {
                self.parent.distance = String(format: "%.2f m", Double(depth))
            }
        }
    }
}


//struct ARViewContainer: UIViewRepresentable {
//    @Binding var distance: String
//    @Binding var screenCenterY: CGFloat  // 添加这一行
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    func makeUIView(context: Context) -> ARSCNView {
//        let arView = ARSCNView()
//        context.coordinator.arView = arView
//        
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = [.horizontal, .vertical]
//        configuration.sceneReconstruction = .mesh
//        configuration.frameSemantics = .sceneDepth
//        arView.session.run(configuration)
//        
//        arView.delegate = context.coordinator
//        
//        return arView
//    }
//    
//    func updateUIView(_ uiView: ARSCNView, context: Context) {}
//    
//    class Coordinator: NSObject, ARSCNViewDelegate {
//        var parent: ARViewContainer
//        var arView: ARSCNView?
//        
//        init(_ parent: ARViewContainer) {
//            self.parent = parent
//        }
//        
//        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//            guard let arView = self.arView else { return }
//            let screenCenterX = arView.bounds.midX
//            let screenCenterY = arView.bounds.midY
//            let screenCenter = CGPoint(x: screenCenterX, y: screenCenterY)
//            parent.screenCenterY = screenCenterY
//            
//            guard let currentFrame = arView.session.currentFrame else {
//                self.parent.distance = "No distance detected."
//                return
//            }
//            
//            // 检查是否支持深度
//            guard let depthData = currentFrame.sceneDepth else {
//                self.parent.distance = "Depth not available."
//                return
//            }
//            
//            // 从相机变换矩阵中提取位置和方向
//            let cameraTransform = currentFrame.camera.transform
//            let cameraPosition = simd_make_float3(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
//            let cameraDirection = simd_make_float3(-cameraTransform.columns.2.x, -cameraTransform.columns.2.y, -cameraTransform.columns.2.z)
//            
//            // 使用射线检测来找到屏幕中心点对应的平面
//            let raycastQuery = ARRaycastQuery(origin: cameraPosition,
//                                              direction: cameraDirection,
//                                              allowing: .estimatedPlane, alignment: .any)
//            
//            let raycastResults = arView.session.raycast(raycastQuery)
//            
//            if let firstResult = raycastResults.first {
//                // 如果找到了平面,使用平面上的点来测量深度
//                let planePoint = simd_make_float3(firstResult.worldTransform.columns.3.x, firstResult.worldTransform.columns.3.y, firstResult.worldTransform.columns.3.z)
//                
//                // 将平面上的3D点转换为2D屏幕坐标
//                let planePointProjected = arView.projectPoint(SCNVector3(planePoint))
//                
//                // 将2D屏幕坐标转换为深度图像坐标
//                let depthPoint = CGPoint(
//                    x: CGFloat(planePointProjected.x) / arView.bounds.width * CGFloat(CVPixelBufferGetWidth(depthData.depthMap)),
//                    y: CGFloat(planePointProjected.y) / arView.bounds.height * CGFloat(CVPixelBufferGetHeight(depthData.depthMap))
//                )
//                
//                // 获取该点的深度值
//                CVPixelBufferLockBaseAddress(depthData.depthMap, .readOnly)
//                let rowData = CVPixelBufferGetBaseAddress(depthData.depthMap)! + Int(depthPoint.y) * CVPixelBufferGetBytesPerRow(depthData.depthMap)
//                let depthPointer = rowData.assumingMemoryBound(to: Float32.self)
//                let depth = depthPointer[Int(depthPoint.x)]
//                CVPixelBufferUnlockBaseAddress(depthData.depthMap, .readOnly)
//                
//                if depth.isNaN || depth > 5.0 {
//                    self.parent.distance = "Out of range"
//                } else {
//                    self.parent.distance = String(format: "%.2f m", Double(depth))
//                }
//            } else {
//                // 如果没有找到平面,显示"No surface detected"
//                self.parent.distance = "No surface detected"
//            }
//        }
//
//    }
//}
