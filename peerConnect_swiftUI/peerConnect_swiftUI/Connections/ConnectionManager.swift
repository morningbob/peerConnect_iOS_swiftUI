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
    @Published var peersInfo : [PeerInfo] = []
    
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
    @Published var connectedPeerInfo: PeerInfo?
    @Published var connectionState = ConnectionState.listening
    @Published var appState = AppState.normal {
        didSet {
            if (appState == AppState.endChat) {
                print("endChat detected, reset starts")
                self.resetSelectedPeers()
            }
        }
    }
    var isHost = false
    private let key = "7431rk"
    // this variable is to record if the app goes from connecting or connected state to notConnected state
    // if it is 1, it goes from connected state to notConnected state, so it is user ends the chat or
    //   there is technical difficulties.
    // if it is 0, it goes from connecting state to notConnected state, so it is the peer refused the
    //   invitation.
    private var fromConnectedOrConnecting = 0
    var endChatState = false
    
    //init(_ peerReceivedHandler: PeerReceivedHandler? = nil) {
    override init() {
        //myPeerId = MCPeerID(displayName: UIDevice.current.name)
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

    func inviteConnect(peerID: MCPeerID) {
        let context = myPeerId.displayName.data(using: .utf8)
        nearbyServiceBrowser.invitePeer(peerID, to: session, withContext: context, timeout: TimeInterval(120))
        
    }
    
    private func createPeerInfo(peer: MCPeerID) -> PeerInfo {
        return PeerInfo(peer: peer)
    }
    
    private func createMessageModel(message: String, whoSaid: String) -> MessageModel {
        let peerNames = getPeerNameString()
        return MessageModel(content: message, peerName: peerNames, whoSaid: whoSaid)
    }
    
    func sendMessage(_ message: String, peersToSend: [MCPeerID], whoSaid: String) -> Bool {
        var success = false
            
        do {
            let data = try JSONEncoder().encode(message)
            //let peers = getPeerIDs(peerInfoList: peerInfoList)
            try session.send(data, toPeers: peersToSend, with: .reliable)
            print("send message success")
            success = true
        } catch {
            print(error.localizedDescription)
            print("send message failed")
            success = false
        }
        return success
        
    }
    
    func sendMessageToPeers(message: String, whoSaid: String) {
        // here we decide if the user is the server or the client by looking at isHost
        // if he is the server, we use the peers list from peers list view
        // if he is the client, we use the connected peer from invitation
        //rint("sendMessage triggered, \(message) \(peerInfoList.count)")
        var peersToSend : [MCPeerID] = []
        
        // extract the MCPeerID from peersInfo, to send
        for peer in peersInfo {
            if (peer.isChecked) {
                peersToSend.append(peer.peerID)
            }
        }
        
        if !isHost {
            //guard let connectedPeerInfo = self.connectedPeerInfo else {
            //return
            //}
            //print("isHost is false, client side, connected peer")
            guard let connectedPeer = self.connectedPeer else {
                return
            }
            peersToSend = [connectedPeer]
        }
        
        if peersToSend.isEmpty {
            return
        }
        
        if (sendMessage(message, peersToSend: peersToSend, whoSaid: whoSaid)) {
            self.messages.append(message)
            var messageModel = createMessageModel(message: message, whoSaid: whoSaid)
            self.messageModels.append(messageModel)
        }
    }
    
    // this send message method is for server side to redirect messages from other peers to
    // the rest of the peers
    func redirectMessageToPeers(message: String, peersToSend: [MCPeerID], whoSaid: String) {
        // here we need to let the rest of the peers know who said the message
        // here we append the message by a key and the who said
        
        let newMessage = message + self.key + whoSaid
        if (sendMessage(newMessage, peersToSend: peersToSend, whoSaid: whoSaid)) {
            //print("sent redirect message")
        }
    }
    
    private func decodeWhoSaid(message: String) -> Array<String> {
        var indexOfName = 0
        var indexOfMessageEnd = 0
        var resultArray = Array<String>()
        let ranges = message.ranges(of: self.key)
        ranges.forEach {
            //print("decoding who said")
            //print($0.upperBound.utf16Offset(in: message))
            indexOfName = $0.upperBound.utf16Offset(in: message)
            indexOfMessageEnd = $0.lowerBound.utf16Offset(in: message)
        }
        let startOfName = message.index(message.startIndex, offsetBy: indexOfName) //.index(message.startIndex)
        let endOfName = message.endIndex
        let rangeOfName = startOfName..<endOfName
        let name = message[rangeOfName]
        resultArray.append(String(name))
        let endOfMessage = message.index(message.startIndex, offsetBy: indexOfMessageEnd)
        let decodedMessageRange = message.startIndex..<endOfMessage
        let decodedMessage = message[decodedMessageRange]
        resultArray.append(String(decodedMessage))
        //print("decode name result: \(name)")
        //print("decode message result: \(message)")
        return resultArray
    }
    
    func endChat() {
        // should let remote peer knows
        session.disconnect()
    }
    
    private func resetSelectedPeers() {
        for peer in self.peersInfo {
            if (peer.isChecked) {
                peer.isChecked.toggle()
                print("isChecked toggled")
            }
        }
    }
    
    // this name strings is stored in the peers field in the message model
    // is used for database queries later
    private func getPeerNameString() -> [String] {
        var peerNames : [String] = []
        for peer in self.peersInfo {
            if (peer.isChecked) {
                peerNames.append(peer.peerID.displayName)
            }
        }
        return peerNames
    }
     
    func sendFile(peer: MCPeerID) {
        //session.sendResource(at: <#T##URL#>, withName: <#T##String#>, toPeer: peer) { error in
        //    if let error = error {
        //      print(error.localizedDescription)
        //}
        //}
    }
    
    func connectPeers() {
        for peer in self.peersInfo {
            if (peer.isChecked) {
                self.inviteConnect(peerID: peer.peerID)
            }
        }
       
    }
    // this method is only for server side to monitor connection progress
    // this method will be triggered by selectedPeersView,
    // it needs to access if all peers are connected yet
    // we'll count the connected peers here and change the app state
    func getAppState() {
        // if all peers responds, either connected, or not connected states received
        // app state is start chat, else app state is connecting
        // so, when the app state is ready to chat, we can navigate to chat view
        
        // here I set readyToChat as 0, 1, or 2, not true or false, I want to distinguish
        // the case of no selected peer too.
        var readyToChat = 0
        
        var allDisconnected = true
        for peer in self.peersInfo {
            if //(peer.isChecked && (peer.state == PeerState.connected || peer.state == PeerState.fromConnectedToDisconnected || peer.state == PeerState.fromConnectingToNotConnected)) {
                (peer.isChecked && (peer.state == PeerState.connecting)) {
                    allDisconnected = false
                    readyToChat = 1   // someone is still connecting
                break
            } else if (peer.isChecked && peer.state == PeerState.connected) {
                allDisconnected = false
            }
            readyToChat = 2     // there is no one set ready to 1
        }
        
        if (readyToChat == 2 && !allDisconnected) {
            DispatchQueue.main.async {
                self.appState = AppState.connected
            }
            print("model: appState startChat")
            
        } else if (self.endChatState) {
            DispatchQueue.main.async {
                self.appState = AppState.endChat
            }
            print("model: appState end chat")
        } else if (readyToChat == 1) {
            DispatchQueue.main.async {
                self.appState = AppState.connecting
            }
            print("model: appState connecting")
            // so, no peer is connecting or connected
        } else if (allDisconnected && readyToChat == 2) {
            DispatchQueue.main.async {
                self.appState = AppState.normal
            }
            print("model: appState all disconnected, normal state")
        
        } else {
            DispatchQueue.main.async {
                self.appState = AppState.normal
            }
            print("there is no selected peer.")
            // not going to change app state
        }
        // if all peers is in disconnected states, the app state should be normal,
        // that is, not in connecting or connected state
        
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
                self.connectedPeerInfo = PeerInfo(peer: peerID)
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
        if !peers.contains(peerID) && peerID != myPeerId {
            DispatchQueue.main.async {
                //let peerIndex = self.peersInfo.firstIndex(where: { $0.peerID == peerID })
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
}

extension ConnectionManager : MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
       
        switch state {
        case .connected:
            print("Connected, from session")
            //guard let messageToSend = messageToSend else { return }
            fromConnectedOrConnecting = 1
            DispatchQueue.main.async {
                //connectingAlert.dismiss(animated: true)
                //print("should dismiss done")
                guard let peerIndex = self.peersInfo.firstIndex(where: { $0.peerID == peerID }) else {
                    return
                }
                self.peersInfo[peerIndex].state = PeerState.connected
                self.connectionState = ConnectionState.connected
                self.connectedPeer = peerID
                self.getAppState()
                //print("should navigate done")
            }
            
        case .notConnected:
            //print("not connected: \(peerID.displayName)")
            //print("fromConnectedOrConnecting : \(fromConnectedOrConnecting)")
            switch fromConnectedOrConnecting {
            case 1:
                print("not connected state: from connected 1")
                DispatchQueue.main.async {
                    //self.appState = AppState.fromConnectedToDisconnected
                    guard let peerIndex = self.peersInfo.firstIndex(where: { $0.peerID == peerID }) else {
                        return
                    }
                    self.peersInfo[peerIndex].state = PeerState.fromConnectedToDisconnected
                    self.getAppState()
                }
            case 0:
                print("not connected state: from connecting 0")
                DispatchQueue.main.async {
                    //self.appState = AppState.fromConnectingToNotConnected
                    guard let peerIndex = self.peersInfo.firstIndex(where: { $0.peerID == peerID }) else {
                        return
                    }
                    self.peersInfo[peerIndex].state = PeerState.fromConnectingToNotConnected
                    self.getAppState()
                }
            default:
                print("not connected state: 0")
            }
            // reset 
            self.fromConnectedOrConnecting = 0
            DispatchQueue.main.async {
                // not successfully connected, eg peer decline the invitation
                self.connectionState = ConnectionState.notConnected
                self.connectedPeer = nil
            }
            // remote peer should navigate to peerslistview
        case .connecting:
            print("connecting: \(peerID.displayName)")
            fromConnectedOrConnecting = 2
            DispatchQueue.main.async {
                guard let peerIndex = self.peersInfo.firstIndex(where: { $0.peerID == peerID }) else {
                    return
                }
                self.peersInfo[peerIndex].state = PeerState.connecting
                //self.appState = AppState.connecting
                self.connectionState = ConnectionState.connecting
                self.getAppState()
            }
            
        default:
            print("unknown state")
        }
        // we update the app state after states assignments above
        // we should update the app state as a whole whenever peers' connection state changed.
        //self.getAppState()
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(String.self, from: data) else { return }
        print("message received: \(message)")
        // here we also check if the message is a redirect message,
        // we check the key, and get the who said string behind it
        var whoSaid = ""
        var filteredMessage = ""
        var resultArray = Array<String>()
        if (message.contains(self.key)) {
            resultArray = self.decodeWhoSaid(message: message)
            whoSaid = resultArray[0]
            filteredMessage = resultArray[1]
        } else {
            whoSaid = peerID.displayName
            filteredMessage = message
        }
        
        // here we got messages from peers.  Peers can't send to other peers directly,
        // so, the host of the chat will send for them, and send here
        if isHost {
            var restOfPeers : [MCPeerID] = [] // don't need to send to the peer who send the message to the host
            
            // extract the MCPeerID from peersInfo, to send
            for peer in peersInfo {
                if (peer.isChecked && peer.peerID != peerID) {
                    restOfPeers.append(peer.peerID)
                }
            }
            self.redirectMessageToPeers(message: message, peersToSend: restOfPeers, whoSaid: peerID.displayName)
        }
        // here, we need to send the received message to the interface
        DispatchQueue.main.async {
            self.messages.append(message)
            var messageModel = self.createMessageModel(message: filteredMessage, whoSaid: whoSaid)
            //print("always run added to message list \(message)")
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

extension StringProtocol {
    func ranges(of targetString: Self, options: String.CompareOptions = [], locale: Locale? = nil) -> [Range<String.Index>] {

        let result: [Range<String.Index>] = self.indices.compactMap { startIndex in
            let targetStringEndIndex = index(startIndex, offsetBy: targetString.count, limitedBy: endIndex) ?? endIndex
            return range(of: targetString, options: options, range: startIndex..<targetStringEndIndex, locale: locale)
        }
        return result
    }
}



