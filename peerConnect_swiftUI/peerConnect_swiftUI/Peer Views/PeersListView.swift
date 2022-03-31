//
//  PeersListView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import SwiftUI

struct PeersListView: View {
    
    @StateObject var connectionManager = ConnectionManager()
    @ObservedObject var peerListStore : PeerListStore
    
    init(peerListStore: PeerListStore = PeerListStore()) {
        self.peerListStore = peerListStore
        //self.connectionManager = ConnectionManager()
        /*
        { peer in
            peerListStore.peers.append(peer)
            print("peer \(peer.name) added to list store")
        }
         */
    }
    
    var body: some View {
        NavigationView {
            List(connectionManager.peerModels) { peerModel in
                PeerListRowView(peerModel: peerModel)
            }.environmentObject(connectionManager)
        }
        .background(Color(red: 0.7725, green: 0.9412, blue: 0.8157))
    }
}

struct PeersListView_Previews: PreviewProvider {
    static var previews: some View {
        PeersListView(peerListStore: PeerListStore())
    }
}
