//
//  PeerListRowView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import SwiftUI

struct PeerListRowView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    let peerModel: PeerModel
    
    var body: some View {
        NavigationLink(destination:
                        ChatView().environmentObject(connectionManager),
                       isActive: $connectionManager.navigateToChat) {
            HStack {
                Text(peerModel.name)
            }.onTapGesture {
                connectionManager.inviteConnect(peerModel: peerModel)
            }
            /*
                        PeerView(peerModel: peerModel)) {
            HStack {
                Text(peerModel.name)
            }.onTapGesture {
                connectionManager.inviteConnect(peerModel: peerModel)
                
            }
        }.environmentObject(connectionManager)
        */
        }
    }
}

struct PeerListRowView_Previews: PreviewProvider {
    static var previews: some View {
        PeerListRowView( peerModel: PeerModel(name: "Kind")).environmentObject(ConnectionManager())
    }
}
