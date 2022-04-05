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
    @State private var showUnsuccessfulConnection = false
    
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
        /*
        let connectionInfoBinding = Binding<String> (
            get: { self.infoText },
            set: { _ in
                if (connectionManager.connectionState == ConnectionState.connecting) {
                    self.infoText = "Connecting to ..."
                } else {
                    self.infoText = "Please choose a peer."
                }
            }
        )
        */
        VStack {
            List(connectionManager.peerModels) { peerModel in
                PeerListRowView(peerModel: peerModel, chosenPeer: $peer).environmentObject(connectionManager)
            }
            Spacer()
            Text(infoText)
                .padding()
            Spacer()
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
        .alert(isPresented: $showUnsuccessfulConnection) {
            Alert(title: Text("Connection"), message: Text("Connection to peer is not successful.  Either connection is bad or peer rejected the invitation"), dismissButton: .default(Text("Okay")))
            
        }
            
        
        /*
        .onTapGesture {
            if (peer != nil) {
                self.infoText = "Connecting to..."
            } else {
                self.infoText = "Please choose a peer."
            }
        }
        */
        // show the connection status to user
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
        
            /*
            if (state == ConnectionState.connecting) {
                self.infoText = "Connecting to..."
            } else {
                self.infoText = "Please choose a peer."
            }
             */
        
         
        // I put the navigation link here instead of in the VStack,
        // to avoid it to be activated by clicking on it.  It's a SwiftUI bug.
        NavigationLink(destination: ChatView().environmentObject(connectionManager), isActive: navigateBinding) {
            EmptyView()
        }
        
    }
    
}

struct PeersListView_Previews: PreviewProvider {
    static var previews: some View {
        PeersListView(peerListStore: PeerListStore())
    }
}
