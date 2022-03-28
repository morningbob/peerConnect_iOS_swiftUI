//
//  PeersListView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import SwiftUI

struct PeersListView: View {
    @ObservedObject var connectionManager: ConnectionManager
    @ObservedObject var peerListStore: PeerListStore
    
    init(peerListStore: PeerListStore = PeerListStore()) {
        self.peerListStore = peerListStore
        connectionManager = ConnectionManager { peer in
            peerListStore.peers.append(peer)
        }
    }
    
    var body: some View {
        List(ForEach(peerListStore.peers) { peer in
            PeerListRowView(peer: peer).environmentObject(connectionManager))
        }
    }
}

struct PeersListView_Previews: PreviewProvider {
    static var previews: some View {
        PeersListView(peerListStore: PeerListStore())
    }
}
