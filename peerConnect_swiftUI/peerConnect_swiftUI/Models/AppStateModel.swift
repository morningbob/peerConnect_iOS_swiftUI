//
//  AppStateModel.swift
//  peerConnect_swiftUI
//
//  Created by Jessie on 2022-04-07.
//

import Foundation

class AppStateModel : ObservableObject {
    
    var peerStatusList : [PeerStatus] = [] {
        didSet {
            print("peerStatus in AppStateModel didSet")
            getPeerStates()
            getAppState()
        }
    }
    //var peerStatusList : [PeerStatus] = []
    @Published var appState : AppState = AppState.normal
    
    private func getPeerStates() {
        
    }
    
    private func getAppState() {
        // if all peers responds, either connected, or not connected states received
        // app state is start chat, else app state is connecting
        // so, when the app state is ready to chat, we can navigate to chat view
        var readyToChat = true
        //print("num of peerStates: \(peerStates.count)")
        for peerStatus in peerStatusList {
            //print("model: peer state: \(state)")
            //if (state == AppState.connecting || state == AppState.normal) {
            //    readyToChat = false
            //    return
            //}
        }
        if (readyToChat) {
            self.appState = AppState.startChat
            print("model: appState startChat")
        } else {
            self.appState = AppState.connecting
            print("model: appState connecting")
        }
        // if all peers is in disconnected states, the app state should be normal,
        // that is, not in connecting or connected state
        
    }
}
