//
//  PeerDevice.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import Foundation

class PeerListStore: ObservableObject {
    @Published var peers: [PeerModel] = []
    
}

struct PeerModel: Codable, Identifiable {
    var id = UUID()
    let name: String
    
    init(name: String) {
        self.name = name
    }
}
