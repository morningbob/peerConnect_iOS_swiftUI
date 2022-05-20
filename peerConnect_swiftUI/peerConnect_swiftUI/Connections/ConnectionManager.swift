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
    private var listOfSessions : [MCSession] = []
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
    private var host: MCPeerID? = nil
    @Published var hostInfo: PeerInfo? = nil
    @Published var disconnectedPeer: MCPeerID? = nil
    private var canGetAppState = true
    @Published var appState = AppState.normal {
        didSet {
            if (appState == AppState.endChat) {
                // this is for host to detect when all peers disconnected
                // it needs to end the chat.
                print("endChat detected in didSet, no reset")
                self.endChatState = false
                self.resetSelectedPeersAndNormalState()
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
    @Published var endChatState = false
    @Published var sendFileSuccessDict : [String : Bool] = [:]
    
    //init(_ peerReceivedHandler: PeerReceivedHandler? = nil) {
    override init() {
        //self.peerReceivedHandler = peerReceivedHandler
        
        self.nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: nil,
            serviceType: ConnectionManager.service
        )
        
        self.nearbyServiceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ConnectionManager.service)
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
            
        do {
            let data = try JSONEncoder().encode(message)
            //let peers = getPeerIDs(peerInfoList: peerInfoList)
            try session.send(data, toPeers: peersToSend, with: .reliable)
            print("send message success")
            return true
        } catch {
            print(error.localizedDescription)
            print("send message failed")
            return false
        }
        
    }
    
    func sendMessageToPeers(message: String, whoSaid: String) {
        // here we decide if the user is the server or the client by looking at isHost
        // if he is the server, we use the peers list from peers list view
        // if he is the client, we use the connected peer from invitation
        //rint("sendMessage triggered, \(message) \(peerInfoList.count)")
        var peersToSend : [MCPeerID] = []
        
        // extract the MCPeerID from peersInfo, to send
        for peer in self.peersInfo {
            if (peer.isChecked && peer.state == PeerState.connected) {
                print("send message to peers, peer \(peer.peerID.displayName)")
                print("connection: \(peer.state)")
                peersToSend.append(peer.peerID)
            }
        }
        print("isHost : \(isHost)")
        
        if !isHost {
            //guard let connectedPeerInfo = self.connectedPeerInfo else {
            //return
            //}
            //print("isHost is false, client side, connected peer")
            //guard let connectedPeer = self.connectedPeer else {
            //    return
            //}
            print("isHost false")
            print("hostInfo: \(self.hostInfo?.peerID.displayName)")
            peersToSend = [self.hostInfo!.peerID]
        }
        
        
        if peersToSend.isEmpty {
            print("send message to peers, no peer to send, return")
            return
        }
        
        // here I don't check if the sent function success or not.  It is only
        // successful if all peers are connected.
        sendMessage(message, peersToSend: peersToSend, whoSaid: whoSaid)
        
        self.messages.append(message)
        var messageModel = createMessageModel(message: message, whoSaid: whoSaid)
        self.messageModels.append(messageModel)
        
    }
    
    // this send message method is for server side to redirect messages from other peers to
    // the rest of the peers
    func redirectMessageToPeers(message: String, peersToSend: [MCPeerID], whoSaid: String) {
        // here we need to let the rest of the peers know who said the message
        // here we append the message by a key and the who said
        
        let newMessage = message + self.peerNameKey + whoSaid
        if (sendMessage(newMessage, peersToSend: peersToSend, whoSaid: whoSaid)) {
            //print("sent redirect message")
        }
    }
    
    private func decodeWhoSaid(message: String) -> Array<String> {
        var indexOfName = 0
        var indexOfMessageEnd = 0
        var resultArray = Array<String>()
        let ranges = message.ranges(of: self.peerNameKey)
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
    
    private func decodeGroupName(info: String) {
        // add user's name to the group first, we need to avoid duplicates
        // the connected state may be triggered more than once in a chat.
        if (!self.groupMemberNames.contains(self.myPeerId.displayName)) {
            self.groupMemberNames.append(self.myPeerId.displayName)
            print("group names added \(myPeerId.displayName)")
            print("count: \(self.groupMemberNames.count)")
        }
        
        let start = info.index(info.startIndex, offsetBy: 6)
        let memberString = String(info[start...])
        print("memberString \(memberString)")
        self.retrieveNames(memberString: memberString)
        
    }
    
    private func retrieveNames(memberString: String) -> String {
        // if string == "" or nil, return ""
        if (memberString == "" || memberString == nil) {
            return ""
        }
        let endingNameInd = memberString.index(of: "747")
        print("memInd \(endingNameInd)")
        // if string != "" or nil, retrieveNames(newMemberString)
        if endingNameInd != nil {
            let name = memberString[memberString.startIndex..<endingNameInd!]
            print("name \(name)")
            DispatchQueue.main.async {
                if (!self.groupMemberNames.contains(String(name))) {
                    self.groupMemberNames.append(String(name))
                    print("group name added \(String(name))")
                    print("count: \(self.groupMemberNames.count)")
                }
            }
            let begin = memberString.index(endingNameInd!, offsetBy: 3)
            let restMemberString = memberString[begin..<memberString.endIndex]
            print("rest of string \(String(restMemberString))")
            return retrieveNames(memberString: String(restMemberString))
        }
        return ""
    }
    
    
    private func resetSelectedPeersAndNormalState() {
        // in case the session is not closed
        print("reset peers report")
        for peer in self.peersInfo {
            print("peer: \(peer.peerID.displayName)  peer state: \(peer.state)")
        }
        self.groupMemberNames = []
        // reset
        self.endChatState = false
        self.clearMessageList()
        self.clearPeersInfo()
        // here we prepare for new session and chats
        self.createNewSession()
        //self.startBrowsing()
        //self.nearbyServiceAdvertiser.startAdvertisingPeer()
    }
    
    // this name strings is stored in the peers field in the message model
    // is used for database queries later
    func getPeerNameString() -> [String] {
        var peerNames : [String] = []
        for peer in self.peersInfo {
            if (peer.isChecked) {
                peerNames.append(peer.peerID.displayName)
            }
        }
        return peerNames
    }
    
    func getPeerNameStringForState(peerState: PeerState) -> [String] {
        var peerNames : [String] = []
        for peer in self.peersInfo {
            if (peer.isChecked && peer.state == peerState) {
                peerNames.append(peer.peerID.displayName)
            }
        }
        return peerNames
    }
    
    func sendFileToPeers(peersInfo: [PeerInfo], urlChosen: URL) {
        for peer in peersInfo {
            print("start sending to \(peer.peerID.displayName) once")
            self.sendFile(peer: peer.peerID, url: urlChosen)
        }
    }
     
    func sendFile(peer: MCPeerID, url: URL) {
        print("SEND FILE TRIGGERED!!!!!!!")
        session.sendResource(at: url, withName: url.lastPathComponent, toPeer: peer) { error in
            if let error = error {
                print(error.localizedDescription)
                print("result is set to false")
                DispatchQueue.main.async {
                    self.sendFileSuccessDict[peer.displayName] = false
                }
            } else {
                print("file sent to \(peer.displayName) with no error")
                print("result is set to true")
                DispatchQueue.main.async {
                    self.sendFileSuccessDict[peer.displayName] = true
                }
            }
            
        }
    }
    // this must be done by host only
    func connectPeers() {
        print("in connectPeer: isHost: \(self.isHost)")
        for peer in self.peersInfo {
            if (peer.isChecked) {
                print("connect peers is triggered \(peer.peerID.displayName)")
                self.inviteConnect(peerID: peer.peerID)
            }
        }
        // here we stop the browsing and advertising
        // so the other devices nearby can't connect to the user device
        // and mess up with the chat.
        //self.stopBrowsing()
        //self.nearbyServiceAdvertiser.stopAdvertisingPeer()
    }
    
    private func connectToOtherGroupMembers() {
        var peersToConnect : [MCPeerID] = []
        // clear previous connections and start new connection
        
        for i in 0...(self.peersInfo.count - 1) {
            print("peersInfo count \(self.peersInfo.count), i \(i)")
            let peer = self.peersInfo[i]
            print("peer name \(peer.peerID.displayName)")
            DispatchQueue.main.async {
                peer.isChecked = false
            }
            self.peersInfo[i] = peer
        }
        // create new peerinfo and make sure it is unique
        for peer in self.groupMemberNames {
            // find the peer in the peerInfo list, I assume that the user can
            // see the peer.
            let peerInfoIndex = self.peersInfo.firstIndex(where: { $0.peerID.displayName == peer })
            if (peerInfoIndex != nil) {
                print("connect to other members, found a peer in peer list, \(peerInfoIndex)")
                let peerInfo = self.peersInfo[peerInfoIndex!]
                if (peerInfo != nil) {
                    DispatchQueue.main.async {
                        peerInfo.isChecked = true
                    }
                    print("checked one peer \(peerInfo.peerID.displayName)")
                    self.peersInfo[peerInfoIndex!] = peerInfo
                    peersToConnect.append(peerInfo.peerID)
                }
            }
            // if the user can't see the peer, we'll have the host to redirect
            // the message.
        }
        print("connect to other group memebers num: \(peersToConnect.count)")
        //self.connectPeers()
    }
    
    func endChat() {
        // host ends chat here
        // should let remote peer knows
        if isHost {
            // here we clean the peersInfo's states
            // so when the user starts a chat again, the app state is correct.
            // we start a routine to run these commands one by one
            //DispatchQueue.global(qos: .background).sync {
                //self.clearPeersInfo()
            print("start sending end chat message")
            self.endChatMessage()
            print("sent end chat message")
            // cease the update of app state
            self.canGetAppState = false
            //}
        } else {
            // client side
            session.disconnect()
            print("client side disconnect")
            print("creating new session")
            self.createNewSession()
        }
    }
    
    
    // need to do this before cleaning peersInfo,
    // otherwise it will not be cleaned
    private func endChatMessage() {
        let message = "\(endChatMessageKey)end"
        var peersToSend : [MCPeerID] = []
        if isHost {
            for peer in self.peersInfo {
                if (peer.isChecked) {
                    peersToSend.append(peer.peerID)
                }
            }
        }
        var success = false
        // we need to wait for end message to finish before we perform disconnect
        //DispatchQueue.global(qos: .background).sync {
            success = sendMessage(message, peersToSend: peersToSend, whoSaid: "Me")
            print("sending message: \(success)")
            
        //}
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // there is no way to know if the sending finished yet,
            // I will wait for 1.5 seconds before performing disconnection.
            print("perform disconnect after 2.5 seconds")
            self.session.disconnect()
            self.canGetAppState = true
            // here we wait for the disconnect to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.getAppState()
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
        print("getting AppState")
        if self.isHost && self.canGetAppState {
            print("host side")
            var someoneConnecting = 0
            var oneIsNotDisconnected = 0// this is to detect if all peers are disconnected,
            // if so, endOfChat is true
            print("peersInfo count: \(self.peersInfo.count)")
            var allDisconnected = true
            var selectedPeersCount = 0
            for peer in self.peersInfo {
                print("peer: \(peer.peerID.displayName)")
                print("peer status: \(peer.state)")
                if (peer.isChecked && (peer.state == PeerState.connecting)) {
                        allDisconnected = false
                        someoneConnecting = 1   // someone is still connecting
                    print("peer connecting")
                    break
                } else if (peer.isChecked && peer.state == PeerState.connected) {
                    allDisconnected = false
                    print("getAppState: peer connected: \(peer.peerID.displayName)")
                } else if (peer.isChecked  && peer.state != PeerState.fromConnectedToDisconnected && peer.state != PeerState.fromConnectingToNotConnected) {
                    oneIsNotDisconnected = 1  // there is a peer who is not in disconnected or
                    // connected state
                    print("other than disconnected")
                    break
                }
                oneIsNotDisconnected = 2
                someoneConnecting = 2     // there is no one set ready to 1
                selectedPeersCount += 1
            }
            
            print("AppState: endChatState: \(self.endChatState)")
            if (self.endChatState) {
                DispatchQueue.main.async {
                    print("set endChat state because of endChatState")
                    self.appState = AppState.endChat
                    // reset endChatState here
                    self.endChatState = false
                    self.clearPeersInfo()
                }
                print("model: appState end chat")
            } else
             if (someoneConnecting == 2 && !allDisconnected) {
                DispatchQueue.main.async {
                    self.appState = AppState.connected
                }
                print("model: appState startChat")
                
            } else if (oneIsNotDisconnected == 2 && someoneConnecting == 2 && allDisconnected && selectedPeersCount > 0) {
                DispatchQueue.main.async {
                    self.appState = AppState.endChat
                    print("set endChat state because of first conditions")
                }
                 
            } else if (someoneConnecting == 1) {
                DispatchQueue.main.async {
                    self.appState = AppState.connecting
                }
                print("model: appState connecting")
                // so, no peer is connecting or connected
            } else if (allDisconnected && someoneConnecting == 2) {
                DispatchQueue.main.async {
                    self.appState = AppState.disconnected
                }
                print("model: appState all disconnected, normal state")
            
            } else {
                DispatchQueue.main.async {
                    self.appState = AppState.normal
                    print("default: ")
                }
            }
        } else if (self.canGetAppState) {
            // for the client, watch only hostInfo
            if (self.hostInfo != nil ) {
                print("getAppState accessed, for client")
                switch (hostInfo!.state) {
                case PeerState.discovered:
                    self.appState = AppState.normal
                    print("client, normal state")
                case PeerState.connecting:
                    self.appState = AppState.connecting
                    print("client, changed to connecting state")
                case PeerState.connected:
                    self.appState = AppState.connected
                    print("client, changed to connected state")
                case PeerState.fromConnectingToNotConnected:
                    print("client, changed to endChat state")
                    self.appState = AppState.endChat
                case PeerState.fromConnectedToDisconnected:
                    print("client, changed to endChat state")
                    self.appState = AppState.endChat
                default:
                    self.appState = AppState.normal
                }
            }
        }
    }
    
    func getGroupInfo(peerID: MCPeerID) -> String {
        var groupNames = getPeerNameString()
        // add the host name too.
        groupNames.append(myPeerId.displayName)
        let peer = groupNames.firstIndex(where: { $0 == peerID.displayName })
        // remove the name of the targeted peer (the client)
        if peer != nil {
            groupNames.remove(at: peer!)
        }
        var groupString = groupNameKey
        // 747 is used to separate group names
        for peer in groupNames {
            groupString += "\(peer)747"
        }
        return groupString
    }
    
    private func keepConnectionWithPeers() {
        for peer in self.peersInfo {
            //if (peer.state
        }
    }
    
    private func checkDuplicatedMessage(message: String, whoSaid: String) -> Bool {
        // here we compare the new message with the messages in the messages strings
        var duplicated = false
        // we check both name and message
        for (index, messageModel) in messageModels.enumerated().reversed() {
            print("index \(index) message \(messageModel.content)")
            if (messageModels.count > 3) {
                if (index < (messageModels.count - 2)) {
                    print("break out of loop when checked 3 messages")
                    break
                }
            }
            if (message == messageModel.content && whoSaid == messageModel.whoSaid) {
                // duplicated
                duplicated = true
            }
        }
        return duplicated
    }
    
    func clearMessageList() {
        self.messageModels = []
        self.messages = []
    }
    
    private func clearPeersInfo() {
        self.canGetAppState = false
        DispatchQueue.main.async {
            self.connectedPeer = nil
            self.connectedPeerInfo = nil
            self.hostInfo = nil
            self.disconnectedPeer = nil
            self.isHost = false
            print("cleaning starts")
            // run cleaning here to intentionally blocks the other method to access
            // peersInfo before it is cleaned up.
            for i in 0...self.peersInfo.count - 1 {
                //if (self.peersInfo[i].isChecked || self.peersInfo[i].state != PeerState.discovered) {
                // this is done for triggering the change of peersInfo,
                // so the chat view, peers info will display it
                
                var peer = self.peersInfo[i]
                print("cleaned peer \(peer.peerID.displayName )")
                peer.isChecked = false
                peer.state = PeerState.discovered
                self.peersInfo[i] = peer
                //}
            }
            self.canGetAppState = true
        }
    }
}

// to receive invitation
// for now, the app likes to refuse invitation automatically when the user is already
// in a chat.
extension ConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // app state connecting or connected means the user already initiated a chat or in the chat
        if (self.appState == AppState.connecting || self.appState == AppState.connected) {
            print("did receive invitation, but ignored it")
            // here we tell the peer who send the invitation, we reject it.
            invitationHandler(false, nil)
            return
        } else {
            
            print("did receive invitation, handling it")
            print("app state: \(self.appState)")
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
                    self.hostInfo = PeerInfo(peer: peerID)
                    self.isHost = false
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
                var peerInfo = self.createPeerInfo(peer: peerID)
                //peerInfo.isConnectable = true
                self.peersInfo.append(peerInfo)
                self.peers.append(peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let peerIndex = self.peersInfo.firstIndex(where: { $0.peerID == peerID }) else {
            return
        }
        // here we keep the peersInfo whenever the peer is discovered,
        // we won't remove the peer, instead, when it is lost, we
        // set the peer as not connectable.
        // I do that because I need to stop browsing and stop advertising
        // so, I don't want the peer to be removed that I can't set it's state
        // when chatting.
        peersInfo.remove(at: peerIndex)
    }
}

extension ConnectionManager : MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
       
        switch state {
        case .connected:
            print("Connected, from session")
            //guard let messageToSend = messageToSend else { return }
            print("connected with \(peerID) now")
            print("isHost: \(self.isHost)")
            fromConnectedOrConnecting = 1
            DispatchQueue.main.async {
                //connectingAlert.dismiss(animated: true)
                //print("should dismiss done")
                // this is for the host, who has checked peersInfo.
                let peerIndex = self.peersInfo.firstIndex(where: { $0.peerID == peerID })
                if (peerIndex != nil) {
                    print("didChange, got peerIndex, changed state to connected, peer: \(peerID.displayName)")
                    // here, we trigger a change in peerInfo, so peer status changes can be detected.
                    var peerInfo = self.peersInfo[peerIndex!]
                    peerInfo.state = PeerState.connected
                    self.peersInfo[peerIndex!] = peerInfo
                } else if (!self.isHost) {
                    // this is for the client, there is no peersInfo checked,
                    // need to set the connectedPeer, that is the host
                    self.hostInfo?.isChecked = true
                    self.hostInfo?.state = PeerState.connected
                    //self.connectedPeerInfo?.isChecked = true
                    //var peerInfo = PeerInfo(peer: self.connectedPeer!)
                    //peerInfo.isChecked = true
                    //self.peersInfo.append(peerInfo)
                }
                
                // here we also set the
                self.getAppState()
                //print("should navigate done")
                
                // here when the state is connected, the host will send members info to all clients
                if (self.isHost) {
                    self.sendMessage(self.getGroupInfo(peerID: peerID), peersToSend: [peerID], whoSaid: "Me")
                    // add to group members variable to display in host's chat view
                    self.decodeGroupName(info: self.getGroupInfo(peerID: self.myPeerId))
                }
            }
            
        case .notConnected:
            switch fromConnectedOrConnecting {
            case 1:
                print("not connected state: from connected 1")
                print("peer: \(peerID.displayName)")
                DispatchQueue.main.async {
                    if !self.isHost {
                        if (self.hostInfo?.peerID == peerID) {
                            self.hostInfo?.state = PeerState.fromConnectedToDisconnected
                            print("set host disconnected state, endChatState = true, host: \(self.hostInfo?.peerID.displayName)")
                            //self.endChatState = true
                        }
                    }
                    
                    guard let peerIndex = self.peersInfo.firstIndex(where: { $0.peerID == peerID }) else {
                        return
                    }
                    print("from connected to disconnected: the peer \(peerID.displayName) set disconnected")
                    var peerInfo = self.peersInfo[peerIndex]
                    peerInfo.state = PeerState.fromConnectedToDisconnected
                    // here we let isChecked = true, when sending message, we'll also
                    // check the state.  so, with isChecked true, we can figure out who
                    // is disconnected and update peer info in chat view.
                    //self.peersInfo[peerIndex].isChecked = false
                    self.peersInfo[peerIndex] = peerInfo
                    self.getAppState()
                }
            case 0:
                print("not connected state: from connecting 0")
                DispatchQueue.main.async {
                    if !self.isHost {
                        if (self.hostInfo?.peerID == peerID) {
                            self.hostInfo?.state = PeerState.fromConnectingToNotConnected
                            print("set host disconnected state, endChatState = true")
                            self.endChatState = true
                        }
                    }
                    
                    guard let peerIndex = self.peersInfo.firstIndex(where: { $0.peerID == peerID }) else {
                        return
                    }
                    print("from connecting to disconnected: the peer \(peerID.displayName) set disconnected")
                    var peerInfo = self.peersInfo[peerIndex]
                    peerInfo.state = PeerState.fromConnectingToNotConnected
                    self.peersInfo[peerIndex] = peerInfo
                    //self.peersInfo[peerIndex].state = PeerState.fromConnectingToNotConnected
                    //self.peersInfo[peerIndex].isChecked = false
                    self.getAppState()
                } 
            default:
                print("not connected state: 0")
            }
            // reset 
            self.fromConnectedOrConnecting = 0
            DispatchQueue.main.async {
                // not successfully connected, eg peer decline the invitation
                self.disconnectedPeer = peerID
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
                if !self.isHost {
                    if (self.hostInfo?.peerID == peerID) {
                        self.hostInfo?.state = PeerState.connecting
                        print("set host connecting state")
                    }
                }
                self.getAppState()
            }
            
        default:
            print("unknown state")
        }
        // we update the app state after states assignments above
        // we should update the app state as a whole whenever peers' connection state changed.
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("did receive message, triggered  message: \(data)")
        guard let message = try? JSONDecoder().decode(String.self, from: data) else { return }
        print("message received: \(message) from peer: \(peerID.displayName)" )
        // here we also check if the message is a redirect message,
        // we check the key, and get the who said string behind it
        var redirect = false
        var showInMessageList = false
        var whoSaid = ""
        var filteredMessage = ""
        var resultArray = Array<String>()
        if (message.contains(self.peerNameKey)) {
            resultArray = self.decodeWhoSaid(message: message)
            whoSaid = resultArray[0]
            filteredMessage = resultArray[1]
            print("got message from peers, need to redirect it \(filteredMessage)")
            showInMessageList = true
        // here we check if the message is from host, for group members
        } else if (message.contains(self.groupNameKey) && !isHost) {
            self.decodeGroupName(info: message)
            print("decodeGroupName ran")
            // setup checked peersInfo
            self.connectToOtherGroupMembers()
        } else if (message.contains("\(self.endChatMessageKey)end")) {
            print("endChatMessage detected in didReceive")
            // this is the server side
            if isHost {
                // won't redirect message, also won't end the chat
                redirect = false
                print("host detected peer \(peerID.displayName)")
            } else {
            // this is client side
                print("client detected peer \(peerID.displayName)")
                //self.endChatState = true
                session.disconnect()
                //self.getAppState()
                //self.clearPeersInfo()
                // manually set app state end chat here
                DispatchQueue.main.async {
                    self.appState = AppState.endChat
                }
            }
            
        //} else if ((message.contains(self.peerNameKey)) || (message.contains(self.groupNameKey)) || message.contains("\(self.endChatMessageKey)end")) && self.isHost {
            // ignore the message
            //redirect = false
            //showInMessageList = false
            
        } else {
            whoSaid = peerID.displayName
            filteredMessage = message
            print("normal message \(message)")
            showInMessageList = true
            redirect = true
        }
        
        // here we got messages from peers.  Peers can't send to other peers directly,
        // so, the host of the chat will send for them, and send here
        if isHost && redirect {
            var restOfPeers : [MCPeerID] = [] // don't need to send to the peer who send the message to the host
            
            // extract the MCPeerID from peersInfo, to send
            for peer in peersInfo {
                if (peer.isChecked && peer.peerID != peerID) {
                    restOfPeers.append(peer.peerID)
                }
            }
            print("redirecting message: \(message)")
            self.redirectMessageToPeers(message: message, peersToSend: restOfPeers, whoSaid: peerID.displayName)
        }
        if (showInMessageList) {
            // here, we need to send the received message to the interface
            DispatchQueue.main.async {
                // here, we also check if the message is duplicate, check upto 3 message in
                // message list
                var duplicated = self.checkDuplicatedMessage(message: filteredMessage, whoSaid: whoSaid)
                if !(duplicated) {
                    self.messages.append(filteredMessage)
                    var messageModel = self.createMessageModel(message: filteredMessage, whoSaid: whoSaid)
                    print("message \(filteredMessage) recorded")
                    //print("always run added to message list \(message)")
                    self.messageModels.append(messageModel)
                    print("not duplicated, checked")
                } else {
                    print("checked, duplicated, ignore")
                }
            }
        }
    }
    
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("connection mgr: starts receiving file")
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        guard
            let localURL = localURL,
            let data = try? Data(contentsOf: localURL)
            //print("data received: \(data)")
        else {
            print("couldn't parse data received.")
            return
        }
        print("data received: \(data)")
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
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string as! Self, options: options).map(\.lowerBound)
    }
}



