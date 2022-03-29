//
//  ConnectionManager.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import Foundation
import MultipeerConnectivity

class ConnectionManager : NSObject, ObservableObject {
    //typealias PeerReceivedHandler = (PeerModel) -> Void
    
    @Published var peers: [MCPeerID] = []
    @Published var peerModels : [PeerModel] = []
    
    private var session: MCSession!
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    //private let peerReceivedHandler: PeerReceivedHandler?
    private static let service = "peer-connect"
    private var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser
    private var nearbyServiceBrowser: MCNearbyServiceBrowser
    
    //init(_ peerReceivedHandler: PeerReceivedHandler? = nil) {
    override init() {
        session = MCSession(
            peer: myPeerId,
            securityIdentity: nil,
            encryptionPreference: .none)
        
        //self.peerReceivedHandler = peerReceivedHandler
        
        self.nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: nil,
            serviceType: ConnectionManager.service
        )
        
        self.nearbyServiceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ConnectionManager.service)
        super.init()
        self.nearbyServiceAdvertiser.delegate = self
        self.nearbyServiceBrowser.delegate = self
        print("start advertising")
        self.nearbyServiceAdvertiser.startAdvertisingPeer()
        print("start browsing")
        startBrowsing()
        //print("connection manager started")
    }
    
    func startBrowsing() {
        print("start discovering")
        nearbyServiceBrowser.startBrowsingForPeers()
    }

    func stopBrowsing() {
        print("stop discovering")
        nearbyServiceBrowser.stopBrowsingForPeers()
    }

    func inviteConnect(peerModel: PeerModel) {
        let context = "hello".data(using: .utf8)
        // retrieve peerID from peers list
        var peerID : MCPeerID? = nil
        for peer in peers {
            if (peer.displayName == peerModel.name) {
                peerID = peer
                break
            }
        }
        if (peerID != nil) {
            print("got peerID")
            nearbyServiceBrowser.invitePeer(peerID!, to: session, withContext: context, timeout: TimeInterval(120))
        } else {
            print("couldn't get peerID")
        }
    }
    
    func createPeerModel(peer: MCPeerID) -> PeerModel {
        return PeerModel(name: peer.displayName)
    }
}

// to advertise user's device is available for connection
extension ConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // get these references for showing alert
        guard
            let window = UIApplication.shared.keyWindow,
            let context = context,
            let name = String(data: context, encoding: .utf8)
        else {
            return
        }
        
        // display alert to user, to accept the connection or candel it.
        let incomingAlert = UIAlertController(title: "Incoming Connection", message: "Do you want to accept the connection request from \(name)", preferredStyle: .alert)
        
        incomingAlert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            // inititiate the chat
            print("confirmed")
            invitationHandler(true, self.session)
        })
        
        incomingAlert.addAction(UIAlertAction(title: "No", style: .cancel)
        {
            _ in
            invitationHandler(false, nil)
        })
        
        window.rootViewController?.present(incomingAlert, animated: true)
    }
}

// store list of peer devices in peers, when a peer is found
extension ConnectionManager : MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("found a device")
        // make sure there is no duplicates
        if !peers.contains(peerID) {
            let peerModel = createPeerModel(peer: peerID)
            print("created a peerModel: \(peerID.displayName)")
            peerModels.append(peerModel)
            peers.append(peerID)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let index = peers.firstIndex(of: peerID) else { return }
        peerModels.remove(at: index)
        peers.remove(at: index)
    }
}

// I need to access window, which UIApplication.shared.windows.first was deprecated
extension UIApplication {
    
    var keyWindow: UIWindow? {
        // Get connected scenes
        return UIApplication.shared.connectedScenes
            // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
            // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
            // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
            // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
    
}

