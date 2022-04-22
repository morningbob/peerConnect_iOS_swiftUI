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
    @State private var infoText = "Please choose a peer.  You can choose up to 7 peers."
    //@State private var showUnsuccessfulConnection = false
    @State private var showConnectingAlert : Bool = false
    // this variable is used to keep track of the num of peer checked,
    // so to avoid checking more than 7 peers.
    @State private var checkedPeers : [PeerInfo] = []
    let maxConnectPeers = 7
    @Environment(\.presentationMode) private var presentationMode
    //@State var showPeerStatus : Bool = false
    
    var body: some View {
        VStack {
            
            List(self.connectionManager.peersInfo, id: \.id) { peerInfo in
                PeerRowView(peerInfo: peerInfo).id(peerInfo.id)
                // contentShape is to set the whole row area as can be tapped.
                .contentShape(Rectangle())
                .onTapGesture {
                    
                    if let checkedIndex =
                        self.connectionManager.peersInfo.firstIndex(where: { $0.id == peerInfo.id }) {
                        if (!self.connectionManager.peersInfo[checkedIndex].isChecked && self.checkedPeers.count >= self.maxConnectPeers) {
                            // alert user that he can only select 7 peers
                            self.showNumberOfPeersAlert()
                        } else {
                            self.connectionManager.peersInfo[checkedIndex].isChecked.toggle()
                                print("toggled")
                                print("peerInfo state: \(self.connectionManager.peersInfo[checkedIndex].isChecked)")
                            // here we analyze if there is more than 7 peers checked
                            if (self.connectionManager.peersInfo[checkedIndex].isChecked) {
                                //self.checkedPeersCount += 1
                                if (!self.checkedPeers.contains(where: { $0.id == self.connectionManager.peersInfo[checkedIndex].id
                                })) {
                                    // add to checkedPeers
                                    self.checkedPeers.append(self.connectionManager.peersInfo[checkedIndex])
                                }
                                print("after checkedPeers append \(self.connectionManager.peersInfo[checkedIndex].peerID.displayName)")
                                print("num of peers: \(checkedPeers.count)")
                                // else if isChecked is false, delete from checkedPeers
                            } else {
                                if let checkedPeerIndex = self.checkedPeers.firstIndex(where: { $0.id == self.connectionManager.peersInfo[checkedIndex].id }) {
                                    self.checkedPeers.remove(at: checkedPeerIndex)
                                    print("after checkedPeers remove")
                                    print("num of peers: \(checkedPeers.count)")
                                }
                            }
                        }
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
                
            } // end of list
            Spacer()
            Text(infoText)
                .padding()
            Spacer()
            
            // when the button is clicked, connection manager connects all
            // peers one by one, when they are all connected, the app will
            // navigate to chat view.  Maybe the app will report those peers that
            // could not be connected.
            HStack {
                Spacer()
                Button(action: {
                    // check if there is checked peer
                    var checkedPeersCount = 0
                    for peer in self.connectionManager.peersInfo {
                        if (peer.isChecked) {
                            checkedPeersCount += 1
                        }
                    }
                    if checkedPeersCount > 0 {
                        self.connectionManager.connectPeers()
                        print("connectPeers is triggered")
                        print("num of peers info: \(self.connectionManager.peersInfo.count)")
                        // this is to distinguish if the app should send messages to peers in the list,
                        // or the connected peer as a client, in the other words, distinguish which
                        // side (server or client) to run send message
                        self.connectionManager.isHost = true
                        self.shouldNavigateToPeerStatus = true
                        //self.showPeerStatus = true
                    } else {
                        self.showChoosePeerAlert()
                    }
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
            } // end of HStack
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
            self.getNewInfo(state: state)
            // this is for the client to navigate to chat view
            //if (!self.connectionManager.isHost && state == AppState.connected) {
            //    self.shouldNavigateToChat = true
            //}
        })
        .onAppear() {
            print("onAppear ran")
            self.getNewInfo(state: self.connectionManager.appState)
        }
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
            
            //guard !peersInfo.isEmpty else { return }

            //withAnimation(Animation.easeInOut) {
            //    proxy.scrollTo(peersInfo.last!.id)
            //}
        })
        /*
        .onReceive(connectionManager.$appState, perform: { state in
            if (state == AppState.connected) {
                print("appState change detected")
                self.shouldNavigateToChat = true
            }
        })
         */
        .onReceive(connectionManager.$hostInfo, perform: { host in
            if (host != nil && !connectionManager.isHost) {
                // we watch the connectedPeer to see if the connection from the server is successful,
                // this is for the client side to navigate to chat view
                guard let index = self.connectionManager.peersInfo.firstIndex(where: { $0.peerID == host!.peerID }) else {
                    return
                }
                // this is for the getAppState method in connection manager, to show correct app state
                // to navigate
                self.connectionManager.peersInfo[index].isChecked = true
                self.shouldNavigateToChat = true
            }
        })
        // for the client to navigate to chat upon clicked confirmed
        /*
        .onReceive(self.connectionManager.$clientShouldNavigateToChat, perform: { navigate in
            if (navigate) {
                self.shouldNavigateToChat = true
            }
        })
         */
        // I put the navigation link here instead of in the VStack,
        // to avoid it to be activated by clicking on it.  It's a SwiftUI bug.
        NavigationLink(destination: SelectedPeersView().environmentObject(connectionManager), //isActive: self.$shouldNavigateToPeerStatus) {
            isActive: self.$shouldNavigateToPeerStatus) {
            EmptyView()
        }//.isDetailLink(false)
        NavigationLink(destination: ChatView().environmentObject(connectionManager), isActive: $shouldNavigateToChat) {
            EmptyView()
        }
       
    }
    
    private func getNewInfo(state: AppState) {
        switch state {
        case AppState.normal:
            self.infoText = "Please choose a peer."
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
    }
    
    private func showChoosePeerAlert() {
        // alert user to choose a peer
        guard let window = UIApplication.shared.keyWindow else {
                return }
        let choosePeerAlert = UIAlertController(title: "Choose a peer", message: "Please choose a peer to connect.  You can choose up to 7 peers.", preferredStyle: .alert)
        
        choosePeerAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            print("confirmed")
        })
    }
    
    private func showNumberOfPeersAlert() {
        guard let window = UIApplication.shared.keyWindow else {
                return }
        
        let numberAlert = UIAlertController(title: "Number of peers", message: "The app can only connect to 7 peers, the maximum.", preferredStyle: .alert)
        
        numberAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // end the chat
            print("confirmed")
            
        })
        
        DispatchQueue.main.async {
            window.rootViewController?.present(numberAlert, animated: true)
        }
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
