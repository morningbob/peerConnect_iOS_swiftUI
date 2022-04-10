//
//  AppStateModel.swift
//  peerConnect_swiftUI
//
//  Created by Jessie on 2022-04-07.
//

import Foundation
import SwiftUI

class AppStateModel : ObservableObject {
    
    //@EnvironmentObject var connectionManager : ConnectionManager
    
    var allPeers : [PeerInfo] = []
        
    @Published var appState : AppState = AppState.normal
    
    func getAppState() {
        // if all peers responds, either connected, or not connected states received
        // app state is start chat, else app state is connecting
        // so, when the app state is ready to chat, we can navigate to chat view
        var readyToChat = true
        for peer in self.allPeers {
            if //(peer.isChecked && (peer.state == PeerState.connected || peer.state == PeerState.fromConnectedToDisconnected || peer.state == PeerState.fromConnectingToNotConnected)) {
                (peer.isChecked && (peer.state == PeerState.connecting)) {
                    readyToChat = false
                break
            }
        }
        
        if (readyToChat) {
            self.appState = AppState.connected
            print("model: appState startChat")
        } else {
            self.appState = AppState.connecting
            print("model: appState connecting")
        }
        // if all peers is in disconnected states, the app state should be normal,
        // that is, not in connecting or connected state
        
    }
}
