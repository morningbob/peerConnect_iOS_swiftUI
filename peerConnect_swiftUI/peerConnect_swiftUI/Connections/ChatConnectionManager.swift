//
//  ChatConnectionManager.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-31.
//

import Foundation
import MultipeerConnectivity

class ChatConnectionManager : NSObject, ObservableObject {
    //typealias PeerReceivedHandler = (PeerModel) -> Void
    
    @Published var peers: [MCPeerID] = []
    @Published var peerModels : [PeerModel] = []
    
    private var session: MCSession!
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    //private let peerReceivedHandler: PeerReceivedHandler?
    //private var myPeerId : MCPeerID?
    private static let service = "peerconnect"
    //private var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser
    //private var nearbyServiceBrowser: MCNearbyServiceBrowser
    private var messageToSend : String? = nil
    @Published var messages : [String] = []
    @Published var messageModels : [MessageModel] = []
    @Published var connectedPeer: MCPeerID? = nil
    @Published var navigateToChat = false
    
    private var advertiserAssistant : MCNearbyServiceAdvertiser?
    
    //init(_ peerReceivedHandler: PeerReceivedHandler? = nil) {
    override init() {
        //myPeerId = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(
            peer: myPeerId,
            securityIdentity: nil,
            encryptionPreference: .none)
        
        //self.peerReceivedHandler = peerReceivedHandler
        /*
        self.nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: nil,
            serviceType: ChatConnectionManager.service
        )
        
        self.nearbyServiceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ChatConnectionManager.service)
        super.init()
        self.nearbyServiceAdvertiser.delegate = self
        self.nearbyServiceBrowser.delegate = self
        print("start advertising")
        self.nearbyServiceAdvertiser.startAdvertisingPeer()
        print("start browsing")
        startBrowsing()
         */
        super.init()
        self.session.delegate = self
        let browserVC = MCBrowserViewController(serviceType: ChatConnectionManager.service, session: session)
        browserVC.delegate = self
        guard
            let window = UIApplication.shared.keyWindow
            //let context = context,
            //let data = String(data: context, encoding: .utf8)
        else { return }
        
        window.rootViewController?.present(browserVC, animated: true)
        //print("connection manager started")
        advertiserAssistant = MCNearbyServiceAdvertiser(
              peer: myPeerId,
              discoveryInfo: nil,
              serviceType: ChatConnectionManager.service)
            advertiserAssistant?.delegate = self
            advertiserAssistant?.startAdvertisingPeer()
    }
}
    /*
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
            //nearbyServiceBrowser.invitePeer(peerID!, to: session, withContext: context, timeout: TimeInterval(120))
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
            self.navigateToChat = true
        } catch {
            print(error.localizedDescription)
        }
    }
}
     */
/*
// to receive invitation
extension ChatConnectionManager: MCNearbyServiceAdvertiserDelegate {
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
            self.connectedPeer = peerID
            self.navigateToChat = true
            invitationHandler(true, self.session)
        })
        
        incomingAlert.addAction(UIAlertAction(title: "No", style: .cancel)
        {
            _ in
            invitationHandler(false, nil)
            print("cancelled")
        })
        
        window.rootViewController?.present(incomingAlert, animated: true)
    }
    
    
}

// store list of peer devices in peers, when a peer is found
extension ChatConnectionManager : MCNearbyServiceBrowserDelegate {
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
        self.connectedPeer = nil
        self.navigateToChat = false
    }
}
*/

extension ChatConnectionManager : MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
        /*
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
            self.connectedPeer = peerID
            self.navigateToChat = true
            invitationHandler(true, self.session)
        })
        
        incomingAlert.addAction(UIAlertAction(title: "No", style: .cancel)
        {
            _ in
            invitationHandler(false, nil)
            print("cancelled")
        })
        
        window.rootViewController?.present(incomingAlert, animated: true)
         */
    }
}

extension ChatConnectionManager : MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true) {
            self.navigateToChat = true
        }
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        session?.disconnect()
        browserViewController.dismiss(animated: true)
    }
    
    
}

extension ChatConnectionManager : MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected")
            //guard let messageToSend = messageToSend else { return }
            //sendMessage("here you go", to: peerID)
            self.connectedPeer = peerID
            self.navigateToChat = true
        case .notConnected:
            print("not connected: \(peerID.displayName)")
            self.connectedPeer = nil
            self.navigateToChat = false
        case .connecting:
            print("connecting: \(peerID.displayName)")
        default:
            print("unknown state")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(String.self, from: data) else { return }
        print("message received: \(message)")
        // here, we need to send the received message to the interface
        self.messages.append(message)
        //var messageModel = createMessageModel(message: message, peerID: peerID, whoSaid: "You")
        //self.messageModels.append(messageModel)
    }
    
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}
