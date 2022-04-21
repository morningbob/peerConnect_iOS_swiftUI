//
//  ChatConnectionManager.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-04-20.
//

import Foundation
import MultipeerConnectivity
import SwiftUI

class ChatConnectionManager : NSObject, ObservableObject, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
   
    private var session: MCSession! {
        didSet {
            if (!session.connectedPeers.isEmpty && !isHost) {
                print("session didSet: create client")
                // create the client to handle chats
                self.client = Client(host: hostPeerInfo, sess: session)
            } else if (!session.connectedPeers.isEmpty && isHost) {
                print("session didSet: create host")
                self.host = Host(peers: self.getSelectedPeers(), sess: session)
            }
        }
    }
    //private var listOfSessions : [MCSession] = []
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private static let service = "peerconnect"
    private var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser
    private var nearbyServiceBrowser: MCNearbyServiceBrowser
    var host: Host!
    var client: Client!
    private var hostPeerID: MCPeerID!
    private var hostPeerInfo: PeerInfo!
    private var initHostOrClient = false
    
    @Published var peers: [MCPeerID] = []
    @Published var peersInfo : [PeerInfo] = []
    private var messageToSend : String? = nil
    @Published var messages : [String] = []
    @Published var messageModels : [MessageModel] = []
    @Published var connectedPeer: MCPeerID? = nil
    @Published var connectedPeerInfo: PeerInfo?
    //private var host: MCPeerID? = nil
    private var hostInfo: PeerInfo? = nil
    @Published var disconnectedPeer: MCPeerID? = nil
    @Published var appState = AppState.normal {
        didSet {
            if (appState == AppState.endChat) {
                // this is for host to detect when all peers disconnected
                // it needs to end the chat.
                print("endChat detected in didSet, reset starts")
                //self.resetSelectedPeersAndNormalState()
            }
        }
    }
    var isHost = false
    // the following keys are for the clients to identify messages sent from the host,
    // for status info.
    private let peerNameKey = "7431rk"
    private let groupNameKey = "3984kg"
    private let endChatMessageKey = "2951fo"
    @Published var groupMemberNames : [String] = []
    // this variable is to record if the app goes from connecting or connected state to notConnected state
    // if it is 1, it goes from connected state to notConnected state, so it is user ends the chat or
    //   there is technical difficulties.
    // if it is 0, it goes from connecting state to notConnected state, so it is the peer refused the
    //   invitation.
    private var fromConnectedOrConnecting = 0
    var endChatState = false
    
    override init() {
        
        self.nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: nil,
            serviceType: ChatConnectionManager.service
        )
        
        self.nearbyServiceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ChatConnectionManager.service)
        super.init()
        self.createNewSession()
        self.nearbyServiceAdvertiser.delegate = self
        self.nearbyServiceBrowser.delegate = self
        print("start advertising")
        self.nearbyServiceAdvertiser.startAdvertisingPeer()
        print("start browsing")
        self.startBrowsing()
        
    }
    
    private func createNewSession() {
        self.session = MCSession(
            peer: myPeerId,
            securityIdentity: nil,
            encryptionPreference: .none)
        //self.listOfSessions.append()
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

    // at the time the connect button is pressed, the app decided the user device
    // act as the host of the chat.  we create the host object to handle the chat.
    func inviteConnect(peerID: MCPeerID) {
        
        
        let context = myPeerId.displayName.data(using: .utf8)
        nearbyServiceBrowser.invitePeer(peerID, to: session, withContext: context, timeout: TimeInterval(120))
        //host = Host(peers: selectedPeers, sess: session)
    }
    
    private func getSelectedPeers() -> [PeerInfo] {
        var selectedPeers : [PeerInfo] = []
        for peer in self.peersInfo {
            if (peer.isChecked) {
                selectedPeers.append(peer)
            }
        }
        return selectedPeers
    }
    
    private func createPeerInfo(peer: MCPeerID) -> PeerInfo {
        return PeerInfo(peer: peer)
    }
    
    func connectPeers() {
        for peer in self.peersInfo {
            if (peer.isChecked) {
                print("connect peers is triggered \(peer.peerID.displayName)")
                self.inviteConnect(peerID: peer.peerID)
            }
        }
        // here we stop the browsing and advertising
        //self.stopBrowsing()
        //self.nearbyServiceAdvertiser.stopAdvertisingPeer()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("found a device")
        // make sure there is no duplicates
        if !peers.contains(peerID) && peerID != myPeerId {
            DispatchQueue.main.async {
                // create new peerInfo
                self.peersInfo.append(self.createPeerInfo(peer: peerID))
                self.peers.append(peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let peerIndex = self.peersInfo.firstIndex(where: { $0.peerID == peerID }) else {
            return
        }
        peersInfo.remove(at: peerIndex)
    }
    
    // the chatCM handles the invitation connections, sending the invitation, response to
    // invitation receive
    // here, if the app accept the incoming invitation, it starts the client object and
    // the client handle the conversation.

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
            //DispatchQueue.main.async {
                // create the client to handle chats
                //self.client = Client(host: peerID)
            //}
            for peer in self.peersInfo {
                if (peer.peerID == peerID) {
                    self.hostPeerInfo = peer
                    break
                }
            }
            //self.hostPeerID = peerID
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

extension ChatConnectionManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("state connected: with peer \(peerID.displayName)")
            // if we couldn't find that peer, we return, maybe warn the user
            guard let index = self.peersInfo.firstIndex(where: { $0.peerID == peerID }) else { return }
            var peerInfo = self.peersInfo[index]
            peerInfo.state = PeerState.connected
             
            self.peersInfo[index] = peerInfo
             
            // create client or host
            if (self.isHost && !self.initHostOrClient) {
                self.host = Host(peers: self.getSelectedPeers(), sess: session, peerConnected: peerInfo)
            } else if (!self.isHost && !self.initHostOrClient) {
                self.client = Client(host: hostPeerInfo, sess: session)
            }
            // this variable makes sure host or client only init once
            self.initHostOrClient = true
            
            
        case .connecting:
            print("state connecting: with peer \(peerID.displayName)")
            
        case .notConnected:
            print("state not connected: with peer \(peerID.displayName)")
        
        
        
        default:
            print("default")
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}

class Host : NSObject, ObservableObject {
    
    var peersSelected : [PeerInfo]!
    var peerConnected : PeerInfo!
    var session : MCSession!
    @Published var messages : [String]!
    @Published var messageModels : [MessageModel]!
    
    init(peers: [PeerInfo], sess: MCSession, peerConnected: PeerInfo) {
        self.peersSelected = peers
        self.session = sess
        self.peerConnected = peerConnected
        super.init()
        self.session.delegate = self
        // after one peer is connected, Host is initiated.  We need to record that
        // peer's state
        self.updatePeerInfoState(peerID: self.peerConnected.peerID, state: PeerState.connected)
        print("init host")
    }
    
    private func updatePeerInfoState(peerID: MCPeerID, state: PeerState) -> Bool {
        var success = false
        guard let index = self.peersSelected.firstIndex(where: { $0.peerID == peerID }) else { return success }
        var peerInfo = self.peersSelected[index]
        peerInfo.state = state
         
        self.peersSelected[index] = peerInfo
        success = true
        return success
    }
}

extension Host : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("state connected: with peer \(peerID.displayName)")
            
            
        case .connecting:
            print("state connecting: with peer \(peerID.displayName)")
            
        case .notConnected:
            print("state not connected: with peer \(peerID.displayName)")
        
        
        
        default:
            print("default")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
}

class Client : NSObject, ObservableObject {
    
    var chatHost : PeerInfo!
    var session : MCSession!
    @Published var messages : [String]!
    @Published var messageModels : [MessageModel]!
    
    init(host: PeerInfo, sess: MCSession) {
        self.chatHost = host
        self.session = sess
        super.init()
        self.session.delegate = self
        print("init client")
    }
}

extension Client : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
}
