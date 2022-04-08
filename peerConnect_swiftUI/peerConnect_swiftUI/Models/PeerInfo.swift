//
//  PeerInfo.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-04-06.
//

import Foundation
import MultipeerConnectivity

class PeerInfo : Identifiable {
    //let name : String
    let id = UUID()
    let peerID : MCPeerID
    var state : PeerState
    var isChecked = false
    
    init(peer: MCPeerID) {
        //self.name = peer.displayName
        self.peerID = peer
        self.state = PeerState.discovered
    }
    
}
