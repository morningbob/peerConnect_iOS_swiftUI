//
//  PeerInfo.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-04-06.
//

import Foundation
import MultipeerConnectivity

class PeerInfo : Identifiable, ObservableObject {
    let id = UUID()
    let peerID : MCPeerID
    @Published var state : PeerState
    @Published var isChecked = false
    @Published var sendFileTo = false
    
    init(peer: MCPeerID) {
        self.peerID = peer
        self.state = PeerState.discovered
    }
    
}
