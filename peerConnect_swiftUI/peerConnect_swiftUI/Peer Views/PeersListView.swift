//
//  PeersListView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import SwiftUI

struct PeersListView: View {
    
    @StateObject var connectionManager = ConnectionManager()
    @ObservedObject var peerListStore : PeerListStore
    
    @State var peer : PeerModel?
    @State private var shouldNavigateToChat = false
    @State private var infoText = "Please choose a peer."
    //@State private var showUnsuccessfulConnection = false
    @State private var peerCheckListItems : [PeerCheckListItem] = []
    @State private var showConnectingAlert : Bool = false
    
    init(peerListStore: PeerListStore = PeerListStore()) {
        self.peerListStore = peerListStore
    }

    var body: some View {
        
        let navigateBinding = Binding<Bool> (
            get: {
                print("binding executed")
                return connectionManager.appState == AppState.connected },
            
            set: {_ in
                if connectionManager.connectionState == ConnectionState.connected {
                    self.shouldNavigateToChat = true
                    print("binding set true")
                } else {
                    self.shouldNavigateToChat = false
                    print("binding set false")
                }
            })
       
        VStack {
            List(peerCheckListItems) { peerItem in
                //PeerListRowView(peerCheckListItem: peerItem, peerCheckListItems: self.peerCheckListItems, chosenPeer: $peer).environmentObject(connectionManager)
                PeerRowView(peerItem: peerItem)
                // contentShape is to set the whole row area as can be tapped.
                .contentShape(Rectangle())
                .onTapGesture {
                    if let checkedIndex =
                        self.peerCheckListItems.firstIndex(where: { $0.id == peerItem.id }) {
                        self.peerCheckListItems[checkedIndex].isChecked.toggle()
                    }
                    // pass peer view model to List View
                    print("set peer in row view")
                    //self.chosenPeer = peerItem.peerModel
                    connectionManager.inviteConnect(peerModel: peerItem.peerModel)
                    self.showConnectingAlert = true
                    
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
            Button(action: {  }) {
                Text("Start Chat")
                    .font(.system(size: 18))
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue, lineWidth: 1))
            }
            Spacer()
        }
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
                print("from onReceive, connected")
                self.infoText = "Connected to peer"
            default:
                print("unknown error")
            }
        })
        .onReceive(connectionManager.$peerModels, perform: { peerModels in
            self.peerCheckListItems = createCheckListItems(peerModels: peerModels)
            
        })
         
        // I put the navigation link here instead of in the VStack,
        // to avoid it to be activated by clicking on it.  It's a SwiftUI bug.
        NavigationLink(destination: ChatView().environmentObject(connectionManager), isActive: navigateBinding) {
            EmptyView()
        }
    }
}

private func createCheckListItems(peerModels: [PeerModel]) -> [PeerCheckListItem] {
    var peerList : [PeerCheckListItem] = []
    for peer in peerModels {
        let peerItem = PeerCheckListItem(id: peer.id, peerModel: peer)
        peerList.append(peerItem)
    }
    return peerList
}

private func selectedPeers(peerItems: [PeerCheckListItem]) -> [PeerModel] {
    var selectedPeers : [PeerModel] = []
    for peer in peerItems {
        if peer.isChecked {
            selectedPeers.append(peer.peerModel)
        }
    }
    return selectedPeers
}

struct PeerRowView : View {
    
    var peerItem : PeerCheckListItem
    
    init(peerItem: PeerCheckListItem) {
        self.peerItem = peerItem
    }
    
    var body: some View {
    
        HStack {
            // this spacer is to use to cover the whole row area such that
            // the user can tap anywhere in the row to trigger onTapGesture
            Text(peerItem.peerModel.name)
            Spacer()
            Text(peerItem.isChecked ? "✅" : "🔲")
        }
    }
}

struct PeerCheckListItem : Identifiable  {
    //var id: ObjectIdentifier
    
    var id : UUID
    var peerModel : PeerModel
    var isChecked : Bool = false
}

struct PeersListView_Previews: PreviewProvider {
    static var previews: some View {
        PeersListView(peerListStore: PeerListStore())
    }
}
