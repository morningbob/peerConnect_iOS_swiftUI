//
//  PeerInfo.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-04-06.
//

import Foundation
import MultipeerConnectivity

class PeerInfo {
    //let name : String
    let id = UUID()
    let peerID : MCPeerID
    var state : AppState
    
    init(peer: MCPeerID) {
        //self.name = peer.displayName
        self.peerID = peer
        self.state = AppState.normal
    }
    
}
