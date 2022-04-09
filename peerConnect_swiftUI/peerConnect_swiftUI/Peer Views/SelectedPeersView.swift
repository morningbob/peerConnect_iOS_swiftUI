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
    @State private var peerStatusList : [PeerStatus] = []
    @State private var shouldNavigateToChat = false
    
    var body: some View {
        
        let navigateBinding = Binding<Bool> (
            get: {
                //print("binding executed")
                return appStateModel.appState == AppState.connected },
            
            set: {_ in
                if appStateModel.appState == AppState.connected {
                    self.shouldNavigateToChat = true
                    //print("binding set true")
                } else {
                    self.shouldNavigateToChat = false
                    //print("binding set false")
                }
            })
        
        VStack {
            
            List(self.peerStatusList) { peer in
                Text(peer.name + " ")
            }
        }
        /*
        .onReceive(self.connectionManager.$selectedPeers, perform: { selectedPeers in
            // create the Peer Status objects
            for peer in selectedPeers {
                let peerStatus = PeerStatus(name: peer.peerID.displayName)
                peerStatusList.append(peerStatus)
            }
        })
         */
        .onReceive(self.connectionManager.$peersInfo, perform: { peersInfo in
            // verified, here, we can observe states changed
            print("peersInfo changed")
            // so we update the peer states here
            for peerStatus in self.peerStatusList {
                // the default state, I set to disconnected.  So, the app state will ignore this peer,
                //peerStatus.state = peersInfo[peerStatus.name]?.state ?? AppState.fromConnectingToNotConnected
                print("peer \(peerStatus.name) new state: \(peerStatus.state)")
            }
        })
        //.onReceive(self.peerStatusList, perform: <#T##(Publisher.Output) -> Void#>)
        .navigationTitle("Peers Status")
        NavigationLink(destination: SelectedPeersView().environmentObject(connectionManager), isActive: navigateBinding) {
            EmptyView()
        }
        
    }
        
}

struct SelectedPeersView_Previews: PreviewProvider {
    static var previews: some View {
        SelectedPeersView()
    }
}

class PeerStatus : Identifiable, ObservableObject {
    
    //var state : AppState
    // we need to observe the state from connection manager
    // that is the state in connectionManager.peersInfo[], not in selectedPeers
    @Published var state = AppState.normal
    var status : String = ""
    let name : String
    
    init(name: String) {
        self.name = name
    }
    
}
