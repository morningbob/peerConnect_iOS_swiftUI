//
//  PeerView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import SwiftUI

struct PeerView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    let peerModel: PeerModel
    
    var body: some View {
        Text(peerModel.name)
         
    }
}

struct PeerView_Previews: PreviewProvider {
    static var previews: some View {
        PeerView(peerModel: PeerModel(name: "Chaos")).environmentObject(ConnectionManager())
    }
}
