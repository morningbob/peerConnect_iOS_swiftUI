//
//  ConnectionManager.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import Foundation
import MultipeerConnectivity
import SwiftUI

class ConnectionManager : NSObject, ObservableObject {
    //typealias PeerReceivedHandler = (PeerModel) -> Void
    
    @Published var peers: [MCPeerID] = []
    @Published var peerModels : [PeerModel] = []
    
    private var session: MCSession!
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    //private let peerReceivedHandler: PeerReceivedHandler?
    private static let service = "peerconnect"
    private var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser
    private var nearbyServiceBrowser: MCNearbyServiceBrowser
    private var messageToSend : String? = nil
    @Published var messages : [String] = []
    @Published var messageModels : [MessageModel] = []
    @Published var connectedPeer: MCPeerID? = nil
    @Published var navigateToChat = false
    @Published var connectionState = ConnectionState.listening
    @Published var appState = AppState.normal
    // this variable is to record if the app goes from connecting or connected state to notConnected state
    // if it is 1, it goes from connected state to notConnected state, so it is user ends the chat or
    //   there is technical difficulties.
    // if it is 0, it goes from connecting state to notConnected state, so it is the peer refused the
    //   invitation.
    private var fromConnectedOrConnecting = 0
    
    //@Binding var shouldNavigate : Bool?
    
    //init(_ peerReceivedHandler: PeerReceivedHandler? = nil) {
    override init() {
        //myPeerId = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(
            peer: myPeerId,
            securityIdentity: nil,
            encryptionPreference: .none)
        
        //self.peerReceivedHandler = peerReceivedHandler
        //self._shouldNavigate = shouldNavigate
        
        self.nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: nil,
            serviceType: ConnectionManager.service
        )
        
        //self._shouldNavigate = shouldNavigate
        
        self.nearbyServiceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ConnectionManager.service)
        //self.shouldNavigate = false
        super.init()
        self.nearbyServiceAdvertiser.delegate = self
        self.nearbyServiceBrowser.delegate = self
        print("start advertising")
        self.nearbyServiceAdvertiser.startAdvertisingPeer()
        print("start browsing")
        startBrowsing()
        self.session.delegate = self
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
        let context = myPeerId.displayName.data(using: .utf8)
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
    
    private func createPeerModel(peer: MCPeerID) -> PeerModel {
        return PeerModel(name: peer.displayName)
    }
    
    private func createMessageModel(message: String, peerID: MCPeerID, whoSaid: String) -> MessageModel {
        return MessageModel(content: message, peerName: peerID.displayName, whoSaid: whoSaid)
    }
    
    func sendMessage(_ message: String, to peer: MCPeerID) {
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: [peer], with: .reliable)
            // add to messages
            self.messages.append(message)
            var messageModel = createMessageModel(message: message, peerID: peer, whoSaid: "Me")
            self.messageModels.append(messageModel)
            // temporary set here navigate to chat
            //self.navigateToChat = true
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func endChat() {
        // should let remote peer knows
        session.disconnect()
    }
    
    func sendFile(peer: MCPeerID) {
        //session.sendResource(at: <#T##URL#>, withName: <#T##String#>, toPeer: peer) { error in
        //    if let error = error {
        //      print(error.localizedDescription)
        //}
        //}
    }
}

// to receive invitation
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
        print("did receive invitation")
        // display alert to user, to accept the connection or candel it.
        let incomingAlert = UIAlertController(title: "Incoming Connection", message: "Do you want to accept the connection request from \(name)", preferredStyle: .alert)
        
        incomingAlert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            // inititiate the chat
            print("confirmed")
            DispatchQueue.main.async {
                self.connectedPeer = peerID
                //self.navigateToChat = true
                //self.shouldNavigate = true
            }
            invitationHandler(true, self.session)
        })
        
        incomingAlert.addAction(UIAlertAction(title: "No", style: .cancel)
        {
            _ in
            invitationHandler(false, nil)
            print("cancelled")
        })
        DispatchQueue.main.async {
            window.rootViewController?.present(incomingAlert, animated: true)
        }
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
            DispatchQueue.main.async {
                self.peerModels.append(peerModel)
                self.peers.append(peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let index = peers.firstIndex(of: peerID) else { return }
        peerModels.remove(at: index)
        peers.remove(at: index)
        DispatchQueue.main.async {
            self.connectedPeer = nil
            self.navigateToChat = false
        }
    }
}

extension ConnectionManager : MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        //guard let window = UIApplication.shared.keyWindow else { return }
        //let connectingAlert = UIAlertController(title: "Connecting...", message: "Connecting to \(peerID.displayName), please wait", preferredStyle: .alert)
        print("state variable: \(state)")
        //var fromConnectedOrConnecting = 0
        switch state {
        case .connected:
            
            print("Connected, from session")
            //guard let messageToSend = messageToSend else { return }
            //sendMessage("here you go", to: peerID)
            fromConnectedOrConnecting = 1
            DispatchQueue.main.async {
                //connectingAlert.dismiss(animated: true)
                //print("should dismiss done")
                self.connectionState = ConnectionState.connected
                self.appState = AppState.connected
                self.connectedPeer = peerID
                self.navigateToChat = true
                print("should navigate done")
            }
        case .notConnected:
            print("not connected: \(peerID.displayName)")
            print("fromConnectedOrConnecting : \(fromConnectedOrConnecting)")
            switch fromConnectedOrConnecting {
            case 1:
                print("not connected state: from connected 1")
                appState = AppState.fromConnectedToDisconnected
            case 0:
                print("not connected state: from connecting 0")
                appState = AppState.fromConnectingToNotConnected
            default:
                print("not connected state: 0")
            }
            // reset 
            self.fromConnectedOrConnecting = 0
            DispatchQueue.main.async {
                // not successfully connected, eg peer decline the invitation
                self.connectionState = ConnectionState.notConnected
                self.connectedPeer = nil
                self.navigateToChat = false
            }
            // remote peer should navigate to peerslistview
        case .connecting:
            print("connecting: \(peerID.displayName)")
            fromConnectedOrConnecting = 2
            DispatchQueue.main.async {
                self.appState = AppState.connecting
                self.connectionState = ConnectionState.connecting
            }
            /*
            connectingAlert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
                // inititiate the chat
                print("confirmed")
                self.connectedPeer = peerID
                self.navigateToChat = true
                //invitationHandler(true, self.session)
            })
            
            connectingAlert.addAction(UIAlertAction(title: "No", style: .cancel)
            {
                _ in
                //invitationHandler(false, nil)
                print("cancelled")
            })
            */
            //DispatchQueue.main.async {
            //    window.rootViewController?.present(connectingAlert, animated: true)
            //}
        default:
            print("unknown state")
        }
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(String.self, from: data) else { return }
        print("message received: \(message)")
        // here, we need to send the received message to the interface
        DispatchQueue.main.async {
            self.messages.append(message)
            var messageModel = self.createMessageModel(message: message, peerID: peerID, whoSaid: "You")
            self.messageModels.append(messageModel)
        }
    }
    
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
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

