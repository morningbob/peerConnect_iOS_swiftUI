//
//  AppStateModel.swift
//  peerConnect_swiftUI
//
//  Created by Jessie on 2022-04-07.
//

import Foundation

class AppStateModel  {
    
    let peersInfo : [PeerInfo]
    var peerStates : [AppState] = []
    var appState : AppState = AppState.normal
    
    init(infoList: [PeerInfo]) {
        self.peersInfo = infoList
    }
    
    private func getPeerStates() {
        
        for peer in self.peersInfo {
            self.peerStates.append(peer.state)
        }
    }
    
    private func getAppState() {
        // if all peers responds, either connected, or not connected states received
        // app state is start chat, else app state is connecting
        
        
    }
}
