//
//  ViewController.swift
//  AR-Ruler
//
//  Created by Vardhan Agrawal on 1/5/18.
//  Copyright © 2018 Vardhan Agrawal. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

extension SCNGeometry {
    class func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])

    }
}

class NewVC: UIViewController, ARSCNViewDelegate,ARSessionDelegate {
    
    // MARK: - Interface Builder Connections
    @IBOutlet var sceneView: ARSCNView!
    var box : SCNNode!
    var focusSquare = FocusSquare()
    var dragOnInfinitePlanesEnabled = false
    var startPoint : SCNVector3!
    var endPoint : SCNVector3!
    var line : SCNNode!
    var worldPosition : SCNVector3!
    var textNode : SCNNode!
    @IBOutlet weak var indicator: UIImageView!
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.scene = SCNScene()
        // Creates a tap handler and then sets it to a constant
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        
        // Sets the amount of taps needed to trigger the handler
        tapRecognizer.numberOfTapsRequired = 1
        
        // Adds the handler to the scene view
       // sceneView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.debugOptions = .showFeaturePoints
        sceneView.session.run(configuration)
        sceneView.delegate = self
        setupFocusSquare()
        
    }
    
    func drawLine(){
        let node = SCNNode(geometry: SCNGeometry.lineFrom(vector: startPoint, toVector: endPoint))
        self.sceneView.scene.rootNode.addChildNode(node)
        startPoint = nil
        endPoint = nil
        
    }
    
    func drawText()->SCNNode{
        let node = SCNNode()
        
        
        let text = SCNText(string: "hello", extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 1.0)
        text.flatness = 0.01
        text.firstMaterial?.diffuse.contents = UIColor.white
        
        node.geometry = text
        node.position = worldPosition
        //helps to make text always camera facing
        node.constraints = [SCNBillboardConstraint()]

        node.scale = SCNVector3Make(0.01, 0.01, 0.01)
        
        return node
        

        
        
        
        
    }
    
    @IBAction func btnCapture(_ sender: Any) {
        
        if let _ = startPoint{
            endPoint = worldPosition
            let sphere = newSphere(at: worldPosition)
            self.sceneView.scene.rootNode.addChildNode(sphere)
            textNode.position = SCNVector3Make((startPoint.x + endPoint.x)/2.0, (startPoint.y + endPoint.y)/2.0, (startPoint.z + endPoint.z)/2.0)
            drawLine()
            
        } else {
            startPoint = worldPosition
            let sphere = newSphere(at: worldPosition)
            self.sceneView.scene.rootNode.addChildNode(sphere)
            textNode = drawText()
            self.sceneView.scene.rootNode.addChildNode(textNode)
        }
    }
 
    // Called when tap is detected
    @objc func handleTap(sender: UITapGestureRecognizer) {
        
        // Gets the location of the tap and assigns it to a constant
        let location = sender.location(in: sceneView)
        
        // Searches for real world objects such as surfaces and filters out flat surfaces
        let hitTest = sceneView.hitTest(location, types: [ARHitTestResult.ResultType.featurePoint])
        
        // Assigns the most accurate result to a constant if it is non-nil
        guard let result = hitTest.last else { return }
        
        // Converts the matrix_float4x4 to an SCNMatrix4 to be used with SceneKit
        let transform = SCNMatrix4.init(result.worldTransform)
        
        // Creates an SCNVector3 with certain indexes in the matrix
        let vector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
        startPoint = vector
        
        // Makes a new sphere with the created method
        let sphere = newSphere(at: vector)
        self.sceneView.scene.rootNode.addChildNode(sphere)

        
    }
    
    // Creates measuring endpoints
    func newSphere(at position: SCNVector3) -> SCNNode {
        
        // Creates an SCNSphere with a radius of 0.4
        let sphere = SCNSphere(radius: 0.01)
        
        // Converts the sphere into an SCNNode
        let node = SCNNode(geometry: sphere)
        
        // Positions the node based on the passed in position
        node.position = position
        
        // Creates a material that is recognized by SceneKit
        let material = SCNMaterial()
        
        // Converts the contents of the PNG file into the material
        material.diffuse.contents = UIColor.orange
        
        // Creates realistic shadows around the sphere
        material.lightingModel = .blinn
        
        // Wraps the newly made material around the sphere
        sphere.firstMaterial = material
        
        // Returns the node to the function
        return node
        
    }

    
    func setupFocusSquare() {
        focusSquare.hide() //unhide
        focusSquare.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(focusSquare)
    }
    
    func updateText(){
        let tt = textNode.geometry as! SCNText
        let distance = startPoint.distance(from: worldPosition) * 39.37 //default its in meters and by multiplying it to 39.37 we are converting it into inches
        tt.string = "\(distance) inch"
    }
   
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
            let startPos = self.worldPositionFromScreenPosition(self.indicator.center, objectPos: nil)
            if let p = startPos.position {
                let camera = self.sceneView.session.currentFrame?.camera
                let cameraPos = SCNVector3.positionFromTransform(camera!.transform)
                if cameraPos.distance(from: p) < 1.0 && self.line == nil {
                    //updateView(state: false)
                    return
                }
            }
        }
    }

    func updateFocusSquare() {
        let (worldPosition, planeAnchor, _) = worldPositionFromScreenPosition(view.center, objectPos: focusSquare.position)
        if let worldPosition = worldPosition {
                self.worldPosition = worldPosition
            
           
            focusSquare.update(for: worldPosition, planeAnchor: planeAnchor, camera: sceneView.session.currentFrame?.camera)
            
            guard let _ = startPoint,
            let _ = textNode
            else {
                return
            }
            
            if let _ = line {
                line.removeFromParentNode()
            }
            
            line = SCNNode(geometry:  SCNGeometry.lineFrom(vector: startPoint, toVector: worldPosition))
            self.textNode.position = worldPosition

            
            sceneView.scene.rootNode.addChildNode(line)
            glLineWidth(20)
            
            
            updateText()
            

            
        }
    }
    
}




extension NewVC {
    
    // Code from Apple PlacingObjects demo: https://developer.apple.com/sample-code/wwdc/2017/PlacingObjects.zip
    
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).
        
        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
    
}
