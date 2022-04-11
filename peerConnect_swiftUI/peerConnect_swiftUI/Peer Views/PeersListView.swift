//
//  PeersListView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import SwiftUI

struct PeersListView: View {
    
    @StateObject var connectionManager = ConnectionManager()
    @State private var shouldNavigateToPeerStatus = false
    @State private var shouldNavigateToChat = false
    @State private var infoText = "Please choose a peer."
    //@State private var showUnsuccessfulConnection = false
    @State private var showConnectingAlert : Bool = false
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        
        VStack {
            List(self.connectionManager.peersInfo) { peerInfo in
                PeerRowView(peerInfo: peerInfo)
                // contentShape is to set the whole row area as can be tapped.
                .contentShape(Rectangle())
                .onTapGesture {
                    if let checkedIndex =
                        self.connectionManager.peersInfo.firstIndex(where: { $0.id == peerInfo.id }) {
                        self.connectionManager.peersInfo[checkedIndex].isChecked.toggle()
                            //peerInfo.isChecked.toggle()
                            //self.connectionManager.peersInfo[checkedIndex] = peerInfo
                            print("toggled")
                            print("peerInfo state: \(self.connectionManager.peersInfo[checkedIndex].isChecked)")
                        
                    }
                }
                .alert("Connecting to ", isPresented: $showConnectingAlert, actions: {
                        
                        })
                // when navigating to chat view, the alert will stay across views
                // so we need to dismiss it manually.
                // this is duplicated in order to make cure the alert is dismissed on time
                .onDisappear() {
                    self.showConnectingAlert = false
                }
                // dismiss the connecting alert if peer rejected connection
                .onReceive(connectionManager.$appState, perform: { state in
                    if (state == AppState.fromConnectedToDisconnected || state == AppState.fromConnectingToNotConnected) {
                        self.showConnectingAlert = false
                    }
                })
                
            }
            Spacer()
            Text(infoText)
                .padding()
            Spacer()
            
            // when the button is clicked, connection manager connects all
            // peers one by one, when they are all connected, the app will
            // navigate to chat view.  Maybe the app will report those peers that
            // could not be connected.
            Button(action: {
                connectionManager.connectPeers()
                // this is to distinguish if the app should send messages to peers in the list,
                // or the connected peer as a client, in the other words, distinguish which
                // side (server or client) to run send message
                connectionManager.isHost = true
                self.shouldNavigateToPeerStatus = true
            })
            {
                Text("Connect")
                    .font(.system(size: 18))
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue, lineWidth: 1))
            }
            Spacer()
            Button(action: {
                // sometimes, the app can't navigate to chat view,
                // here user can navigate manually
                
                self.shouldNavigateToChat = true
            })
            {
                Text("Chat View")
                    .font(.system(size: 18))
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue, lineWidth: 1))
            }
            Spacer()
        }
        .environmentObject(connectionManager)
        .background(Color(red: 0.7725, green: 0.9412, blue: 0.8157))
        .navigationTitle("Peers")
        /*
        .alert(isPresented: $showUnsuccessfulConnection) {
            Alert(title: Text("Connection"), message: Text("Connection to peer is not successful.  Either connection is bad or peer rejected the invitation"), dismissButton: .default(Text("Okay")))
            
        }
         */
            
        .onReceive(connectionManager.$appState, perform: { state in
            
            switch state {
            case AppState.fromConnectingToNotConnected:
                self.infoText = "Could not connect to peer.  Please choose a peer."
            case AppState.fromConnectedToDisconnected:
                self.infoText = "Bad connection or peer disconnected."
            case AppState.connecting:
                self.infoText = "Connecting to peer"
            case AppState.connected:
                //print("from onReceive, connected")
                self.infoText = "Connected to peer"
            default:
                print("unknown error")
            }
        })
        .onReceive(connectionManager.$peersInfo, perform: { peersInfo in
            print("Peer list view, peerInfo changed")
            var i = 0
            for peer in peersInfo {
                if (peer.isChecked) {
                    print("checked \(peer.peerID.displayName)")
                    i += 1
                }
            }
            print("total peers: \(String(i))")
        })
        /*
        .onReceive(connectionManager.$appState, perform: { state in
            if (state == AppState.connected) {
                print("appState change detected")
                self.shouldNavigateToChat = true
            }
        })
         */
        .onReceive(connectionManager.$connectedPeer, perform: { connectedPeer in
            if (connectedPeer != nil && !connectionManager.isHost) {
                // we watch the connectedPeer to see if the connection from the server is successful,
                // this is for the client side to navigate to chat view
                guard let index = self.connectionManager.peersInfo.firstIndex(where: { $0.peerID == connectedPeer }) else {
                    return
                }
                // this is for the getAppState method in connection manager, to show correct app state
                // to navigate
                self.connectionManager.peersInfo[index].isChecked = true
                self.shouldNavigateToChat = true
            }
        })
         
        // I put the navigation link here instead of in the VStack,
        // to avoid it to be activated by clicking on it.  It's a SwiftUI bug.
        NavigationLink(destination: SelectedPeersView().environmentObject(connectionManager), isActive: self.$shouldNavigateToPeerStatus) {
            EmptyView()
        }.isDetailLink(false)
        NavigationLink(destination: ChatView().environmentObject(connectionManager), isActive: $shouldNavigateToChat) {
            EmptyView()
        }
        /*
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
             case .active:
              //open QR Scanner when app is resumed
              self.QRScannerisPresented = true
              return
            case .background:
             //app moves to backgound
             return
            case .inactive:
             return
            @unknown default:
             return
             }
            }
         */
        
    }
    
}

struct PeerRowView : View {
    
    @ObservedObject var peerInfo : PeerInfo
    
    init(peerInfo: PeerInfo) {
        self.peerInfo = peerInfo
    }
    
    var body: some View {
    
        HStack {
            // this spacer is to use to cover the whole row area such that
            // the user can tap anywhere in the row to trigger onTapGesture
            Text(peerInfo.peerID.displayName)
            Spacer()
            Text(peerInfo.isChecked ? "✅" : "🔲")
            //Text("isCheck \(String(peerInfo.isChecked))")
        }
    }
}

private func createCheckListItems(peersInfo: [PeerInfo]) -> [PeerCheckListItem] {
    var peerList : [PeerCheckListItem] = []
    for peer in peersInfo {
        let peerItem = PeerCheckListItem(id: peer.id, peerInfo: peer)
        peerList.append(peerItem)
    }
    return peerList
}

private func selectedPeers(peerItems: [PeerCheckListItem]) -> [PeerInfo] {
    var selectedPeers : [PeerInfo] = []
    for peer in peerItems {
        if peer.isChecked {
            selectedPeers.append(peer.peerInfo)
        }
    }
    return selectedPeers
}



struct PeerCheckListItem : Identifiable  {
    
    var id : UUID
    var peerInfo : PeerInfo
    var isChecked : Bool = false
}

struct PeersListView_Previews: PreviewProvider {
    static var previews: some View {
        PeersListView()
    }
}
/*
 let navigateBinding = Binding<Bool> (
     get: {
         //print("binding executed")
         return connectionManager.appState == AppState.connected },
     
     set: {_ in
         if connectionManager.connectionState == ConnectionState.connected {
             self.shouldNavigateToPeerStatus = true
             //print("binding set true")
         } else {
             self.shouldNavigateToPeerStatus = false
             //print("binding set false")
         }
     })
 */
