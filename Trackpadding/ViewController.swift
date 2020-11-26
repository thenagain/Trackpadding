//
//  ViewController.swift
//  Trackpadding
//
//  Created by thenagain on 2020/11/25.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCSessionDelegate, MCNearbyServiceBrowserDelegate {
    
    // MARK: - Properties
    @IBOutlet weak var gestureLabel: UILabel!
    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet var oneFingerTapTrackpadRecognizer: UITapGestureRecognizer!
    @IBOutlet var twoFingerTapTrackpadRecognizer: UITapGestureRecognizer!
    
    var mcPeerID: MCPeerID!
    var mcSession: MCSession!
    var mcBrowser: MCNearbyServiceBrowser!
    var previousTranslation: CGPoint = CGPoint.init()
    var peersDisplayName: String = ""
    
    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        oneFingerTapTrackpadRecognizer.require(toFail: twoFingerTapTrackpadRecognizer)
        
        startMCSession()
    }
    
    // MARK: - User Interaction
    /// - Tag: Trackpad Interaction
    @IBAction func oneFingerTapTrackpad(_ sender: UITapGestureRecognizer) {
        gestureLabel.text = "Left Click"
        sendCommand(gesture: "1Tap")
    }
    
    @IBAction func twoFingerTapTrackpad(_ sender: UITapGestureRecognizer) {
        gestureLabel.text = "Right Click"
        sendCommand(gesture: "2Tap")
    }
    
    @IBAction func oneFingerPanTrackpad(_ sender: UIPanGestureRecognizer) {
        let deltaTranslation = getDeltaTranslation(sender: sender)
        gestureLabel.text = "Cursor Move dx:\(deltaTranslation.x) dy:\(deltaTranslation.y)"
        sendCommand(gesture: "1Pan \(deltaTranslation.x) \(deltaTranslation.y)")
    }
    
    @IBAction func twoFingerPanTrackpad(_ sender: UIPanGestureRecognizer) {
        let deltaTranslation = getDeltaTranslation(sender: sender)
        gestureLabel.text = "Scroll dx:\(deltaTranslation.x) dy:\(deltaTranslation.y)"
        sendCommand(gesture: "2Pan \(deltaTranslation.x) \(deltaTranslation.y)")
    }
    
    /// - Tag: Other Interaction
    @IBAction func tapRestartButton(_ sender: UITapGestureRecognizer) {
        stopMCSession()
        startMCSession()
    }
    
    // MARK: - Function
    func startMCSession() {
        mcPeerID = MCPeerID.init(displayName: UIDevice.current.name)
        mcSession = MCSession.init(peer: mcPeerID!)
        mcSession.delegate = self
        mcBrowser = MCNearbyServiceBrowser.init(peer: mcPeerID, serviceType: "trackpadding")
        mcBrowser.delegate = self
        mcBrowser.startBrowsingForPeers()
    }
    
    func stopMCSession() {
        mcBrowser.stopBrowsingForPeers()
        mcSession.disconnect()
    }
    
    func sendCommand(gesture: String) {
        guard !mcSession.connectedPeers.isEmpty else {
            return
        }
        
        DispatchQueue.main.async {
            guard let command = gesture.data(using: String.Encoding.utf8) else {
                return
            }
            try? self.mcSession.send(command, toPeers: self.mcSession.connectedPeers, with: MCSessionSendDataMode.unreliable)
        }
    }
    
    func getDeltaTranslation(sender: UIPanGestureRecognizer) -> CGPoint {
        let translation: CGPoint = sender.translation(in: sender.view)
        var deltaTranslation = translation
        
        if sender.state != UIGestureRecognizer.State.began {
            deltaTranslation = CGPoint(x: translation.x - previousTranslation.x, y: translation.y - previousTranslation.y)
        }
        previousTranslation = translation
        return deltaTranslation
    }
    
    // MARK: - Delegate
    /// - Tag: MCSessionDelegate
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectionLabel.text = ("Connected with \(self.peersDisplayName)")
                  
            case .connecting:
                self.connectionLabel.text = ("Connecting with \(self.peersDisplayName)")
                  
            case .notConnected:
                self.connectionLabel.text = ("Not Connected with \(self.peersDisplayName)")
            @unknown default:
                self.connectionLabel.text = ("Session Error")
            }
        }
    }
    /// - Tag: MCNearbyServiceBrowserDelegate
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard peersDisplayName.isEmpty else {
            return
        }
        mcBrowser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: TimeInterval(10))
        peersDisplayName = peerID.displayName
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        peersDisplayName = ""
    }

}

