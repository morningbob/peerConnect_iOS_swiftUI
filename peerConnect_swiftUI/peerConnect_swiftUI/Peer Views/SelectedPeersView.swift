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
    //@State private var peerStatusList : [PeerStatus] = []
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
            // here we input the peersInfo which are selected
            List({
                guard let selectedPeers = self.connectionManager.peersInfo.firstIndex(where: { $0.isChecked }) else {
                    return
                }
                //selectedPeers = selectedPeers
            }) { peerInfo in
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
            //for peerStatus in self.peerStatusList {
                // the default state, I set to disconnected.  So, the app state will ignore this peer,
                //peerStatus.state = peersInfo[peerStatus.name]?.state ?? AppState.fromConnectingToNotConnected
            //    print("peer \(peerStatus.name) new state: \(peerStatus.state)")
            
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

struct PeerStatusView : View {
    
    @ObservedObject var peerInfo : PeerInfo //{
        //didSet {
        //    print("peerInfo changed, didSet triggered")
        //    getNewStatus()
        //}
    //}
    //@State var status : String = ""
        
    
    
    init(peerInfo: PeerInfo) {
        self.peerInfo = peerInfo
    }
    
    var body: some View {
        HStack {
            //Text("good")
            //Text(peerInfo.peerID.displayName + "    "))
            Text(peerInfo.peerID.displayName + ":  " + getNewStatus())
            Text(peerInfo.state == PeerState.connected ? "✅" : "🔲")
        }
        //.onReceive(self.$peerInfo, perform: { peerInfo in
        //    getNewStatus()
        //})
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


