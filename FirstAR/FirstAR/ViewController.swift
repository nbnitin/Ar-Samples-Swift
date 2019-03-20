//
//  ViewController.swift
//  FirstAR
//
//  Created by Nitin Bhatia on 14/03/19.
//  Copyright © 2019 Nitin Bhatia. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class Drone: SCNNode {
    func loadModel() {
        guard let virtualObjectScene = SCNScene(named: "art.scnassets/ship.scn") else { return }
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            wrapperNode.addChildNode(child)
        }
        addChildNode(wrapperNode)
    }
}

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var drone = Drone()
    @IBOutlet weak var btn: UIButton!
    @IBOutlet weak var btnUp: UIButton!
    @IBOutlet weak var btnLeft: UIButton!
    @IBOutlet weak var btnDown: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        let gestLeft = UILongPressGestureRecognizer(target: self, action:#selector(leftLongPressed(_:)))
         let gestRight = UILongPressGestureRecognizer(target: self, action:#selector(rightLongPressed(_:)))
         let gestUp = UILongPressGestureRecognizer(target: self, action:#selector(upLongPressed(_:)))
         let gestDown = UILongPressGestureRecognizer(target: self, action:#selector(downLongPressed(_:)))

        btn.addGestureRecognizer(gestRight)
        btnLeft.addGestureRecognizer(gestLeft)
        btnUp.addGestureRecognizer(gestUp)
        btnDown.addGestureRecognizer(gestDown)

        
        // Create a new scene
        let scene = SCNScene()
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
        //art.scnassets/ship.scn
        guard let virtualObjectScene = SCNScene(named: "art.scnassets/ship.scn") else { return }
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            wrapperNode.addChildNode(child)
        }
        drone.addChildNode(wrapperNode)
       // drone.loadModel()
        sceneView.scene.rootNode.addChildNode(drone)
        
       // let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        
        //Add recognizer to sceneview
        //sceneView.addGestureRecognizer(tap)
        
    }
    
    private func execute(action: SCNAction, sender: UILongPressGestureRecognizer) {
        let loopAction = SCNAction.repeatForever(action)
        if sender.state == .began {
            drone.runAction(loopAction)
        } else if sender.state == .ended {
            drone.removeAllActions()
        }
    }
    
    let kMovingLengthPerLoop: CGFloat = 0.05
    let kRotationRadianPerLoop: CGFloat = 0.2
    
    @IBAction func leftLongPressed(_ sender: UILongPressGestureRecognizer) {
        let action = SCNAction.moveBy(x: -kMovingLengthPerLoop, y: 0, z: 0, duration: 0.3)
        execute(action: action, sender: sender)
    }
    @IBAction func rightLongPressed(_ sender: UILongPressGestureRecognizer) {
        let action = SCNAction.moveBy(x: kMovingLengthPerLoop, y: 0, z: 0, duration: 0.3)
        execute(action: action, sender: sender)
    }
    @IBAction func upLongPressed(_ sender: UILongPressGestureRecognizer) {
        let action = SCNAction.moveBy(x: 0, y: kMovingLengthPerLoop, z: 0, duration: 0.3)
        execute(action: action, sender: sender)
    }
    @IBAction func downLongPressed(_ sender: UILongPressGestureRecognizer) {
        let action = SCNAction.moveBy(x: 0, y: -kMovingLengthPerLoop, z: 0, duration: 0.3)
        execute(action: action, sender: sender)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
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
    
    func addNewNode(result:ARHitTestResult){
        // create a simple ball
        let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.2))
        
        // create position of ball based on tap result
        let position = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
        
        // set position of ball before adding to scene
        sphereNode.position = position
        
        // each tap adds a new instance of the ball.
        self.sceneView.scene.rootNode.addChildNode(sphereNode)
    }
    
    //Method called when tap
    @objc func handleTap(rec: UITapGestureRecognizer){
        
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            if !hits.isEmpty{
                let tappedNode = hits.first?.node
                return
            }
            let results = sceneView.hitTest(location, types: .featurePoint)


            addNewNode(result: results.first!)
        }
    }
    
//    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
//        guard let pointOfView = sceneView.pointOfView else { return }
//        let transform = pointOfView.transform
//        let orientation = SCNVector3(-transform.m31, -transform.m32, transform.m33)
//        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
//        let currentPositionOfCamera = add(lhv: orientation,rhv: location)
//        print(currentPositionOfCamera)
//        drone.transform = transform
//    }
    
    func add(lhv:SCNVector3, rhv:SCNVector3) -> SCNVector3 {
        return SCNVector3(lhv.x + rhv.x, lhv.y + rhv.y, lhv.z + rhv.z)
    }

    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
