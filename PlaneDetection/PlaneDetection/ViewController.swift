//
//  ViewController.swift
//  PlaneDetection
//
//  Created by Nitin Bhatia on 15/03/19.
//  Copyright © 2019 Nitin Bhatia. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var lblPlaneDetectionLable: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
       // let scene = SCNScene(named: "art.scnassets/ship.scn")!
        let scene = SCNScene()
        // Set the scene to the view
        sceneView.scene = scene
        
        //handle lighting
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        

        // Run the view's session
        sceneView.session.run(configuration)
        //boundingboxes shows for 3dview
        //feature points will detect of plane
        sceneView.debugOptions = .showFeaturePoints
        addTapGestureToSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //Horizontal Planes Visualization
    //Now that the app gets notified every time a new ARAnchor is being added onto sceneView, we may be interested in seeing what that newly added ARAnchor looks like.
    
    /*Let’s me walk you through the code line by line:
    
    We safely unwrap the anchor argument as an ARPlaneAnchor to make sure that we have information about a detected real world flat surface at hand.
    Here, we create an SCNPlane to visualize the ARPlaneAnchor. A SCNPlane is a rectangular “one-sided” plane geometry. We take the unwrapped ARPlaneAnchor extent’s x and z properties and use them to create an SCNPlane. An ARPlaneAnchor extent is the estimated size of the detected plane in the world. We extract the extent’s x and z for the height and width of our SCNPlane. Then we give the plane a transparent light blue color to simulate a body of water.
    We initialize a SCNNode with the SCNPlane geometry we just created.
    We initialize x, y, and z constants to represent the planeAnchor’s center x, y, and z position. This is for our planeNode’s position. We rotate the planeNode’s x euler angle by 90 degrees in the counter-clockerwise direction, else the planeNode will sit up perpendicular to the table. And if you rotate it clockwise, David Blaine will perform a magic illusion because SceneKit renders the SCNPlane surface using the material from one side by default.
    Finally, we add the planeNode as the child node onto the newly added SceneKit node.*/
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor else {  return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        // 3
        plane.materials.first?.diffuse.contents = UIColor(red: 0, green: 0, blue: 255, alpha: 0.6)
        
        // 4
        let planeNode = SCNNode(geometry: plane)
        
        // 5
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // 6
        node.addChildNode(planeNode)
    }
    //Horizontal Planes Expansion
    //With ARKit receiving additional information about our environment, we may want to expand our previously detected horizontal plane(s) to make use of a larger surface or have a more accurate representation with the new information.
    

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addShipToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func addShipToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        guard let hitTestResult = hitTestResults.first else { return }
//        let translation = hitTestResult.worldTransform.columns
//        let x = translation.x
//        let y = translation.y
//        let z = translation.z
        
        guard let shipScene = SCNScene(named: "art.scnassets/ship2.scn"),
            let shipNode = shipScene.rootNode.childNode(withName: "ship", recursively: false)
            else { return }
        
        
        shipNode.position = SCNVector3(hitTestResult.worldTransform.columns.3.x,hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
        sceneView.scene.rootNode.addChildNode(shipNode)
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
