//
//  SelectedPeersView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-04-08.
//

import SwiftUI

struct SelectedPeersView: View {
    
    @EnvironmentObject var connectionManager : ConnectionManager
    @EnvironmentObject var appStateModel : AppStateModel
    @State private var shouldNavigateToChat = false
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        
        let navigateBinding = Binding<Bool> (
            get: {
                //print("binding executed")
                return self.connectionManager.appState == AppState.connected },
            
            set: {_ in
                if self.connectionManager.appState == AppState.connected {
                    self.shouldNavigateToChat = true
                    //print("binding set true")
                } else {
                    self.shouldNavigateToChat = false
                    //print("binding set false")
                }
            })
        
        VStack {
            // here we input the peersInfo which are selected
            
            List(self.connectionManager.peersInfo) { peerInfo in
                // we do the selection here
                if (peerInfo.isChecked) {
                    PeerStatusView(peerInfo: peerInfo)
                }
            }
        }
        
        .onReceive(self.connectionManager.$peersInfo, perform: { peersInfo in
            // verified, here, we can observe states changed
            print("selected peers view, peersInfo changed")
            connectionManager.getAppState()
        })
        .onReceive(self.connectionManager.$appState, perform: { state in
            if (state == AppState.connected) {
                self.shouldNavigateToChat = true
            } else if (state == AppState.endChat) {
                self.presentation.wrappedValue.dismiss()
            }
        })
        .navigationTitle("Peers Status")
        NavigationLink(destination: ChatView().environmentObject(connectionManager).environmentObject(appStateModel), isActive: $shouldNavigateToChat) {
            EmptyView()
        }
        
    }
        
}

struct SelectedPeersView_Previews: PreviewProvider {
    static var previews: some View {
        SelectedPeersView()
    }
}

struct PeerStatusView : View {
    
    @ObservedObject var peerInfo : PeerInfo
    
    init(peerInfo: PeerInfo) {
        self.peerInfo = peerInfo
    }
    
    var body: some View {
        HStack {
            
            Text(peerInfo.peerID.displayName + ":  " + getNewStatus())
            Text(peerInfo.state == PeerState.connected ? "✅" : "🔲")
        }
       
    }
    
    private func getNewStatus() -> String {
        var status = ""
        switch (peerInfo.state) {
        case PeerState.connecting:
            status = "Connecting..."
        case PeerState.fromConnectingToNotConnected:
            status = "Peer refused connection."
        case PeerState.fromConnectedToDisconnected:
            status = "Peer disconnected."
        case PeerState.connected:
            status = "Peer connected."
        default:
            status = "Connecting..."
        }
        return status
    }
}


