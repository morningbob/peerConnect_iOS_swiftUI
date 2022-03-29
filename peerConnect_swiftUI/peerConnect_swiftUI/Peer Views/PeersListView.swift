//
//  PeersListView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import SwiftUI

struct PeersListView: View {
    
    @ObservedObject var connectionManager : ConnectionManager
    @ObservedObject var peerListStore : PeerListStore
    
    init(peerListStore: PeerListStore = PeerListStore()) {
    //init() {
        self.peerListStore = peerListStore
        self.connectionManager = ConnectionManager()
        { peer in
            peerListStore.peers.append(peer)
        }
    }
    
    var body: some View {
        List(connectionManager.peerModels) { peerModel in
            PeerListRowView(peerModel: peerModel)
        }
    }
}

struct PeersListView_Previews: PreviewProvider {
    static var previews: some View {
        PeersListView(peerListStore: PeerListStore())
    }
}
