//
//  PeerDevice.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import Foundation
import MultipeerConnectivity

class PeerListStore: ObservableObject {
    @Published var peers: [PeerModel] = []
    
}

struct PeerModel: Codable, Identifiable, Equatable {
    var id = UUID()
    let name : String
    //var state : AppState
    //let peerID : MCPeerID
    
}
