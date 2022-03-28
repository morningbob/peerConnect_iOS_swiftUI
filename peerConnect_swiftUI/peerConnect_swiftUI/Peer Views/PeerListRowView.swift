//
//  PeerListRowView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import SwiftUI

struct PeerListRowView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    let peer: PeerModel
    
    var body: some View {
        NavigationLink(title: "Peer", destination: PeerView(peer: peer).environmentObject(connectionManager)) {
            HStack {
                Text(peer.name)
            }
        }
        
    }
}

struct PeerListRowView_Previews: PreviewProvider {
    static var previews: some View {
        PeerListRowView(peer: PeerModel(name: "Kind")).environmentObject(ConnectionManager()) 
    }
}
