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
    
    init(peerListStore: PeerListStore = PeerListStore()) {
        self.peerListStore = peerListStore
        
    }

    var body: some View {
        
        VStack {
            List(connectionManager.peerModels) { peerModel in
                PeerListRowView(peerModel: peerModel, chosenPeer: $peer).environmentObject(connectionManager)
            }
            
            Spacer()
            Button(action: {  }) {
                Text("Start Chat")
                    .font(.system(size: 18))
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue, lineWidth: 1))
            }
            Spacer()
        }.background(Color(red: 0.7725, green: 0.9412, blue: 0.8157))
            
        
        
        // I put the navigation link here instead of in the VStack,
        // to avoid it to be activated by clicking on it.  It's a SwiftUI bug.
        NavigationLink(destination: ChatView().environmentObject(connectionManager), isActive: $connectionManager.navigateToChat)  {
            EmptyView()
        }
        .onReceive(connectionManager.$navigateToChat, perform: { navigateToChat in
            //let connectingAlert = UIAlertController(title: "Connection", message: "Conecting to \(String(describing: peer?.name)), please wait.", preferredStyle: .alert)
            if (navigateToChat && peer != nil) {
                // dismiss alert, we may not need to dismiss it because we navigate to chat view
                //connectingAlert.dismiss(animated: true)
                print("navigate is true, peer is not nil")
                //self.showConnectingAlert = false
            } else if (!navigateToChat && peer != nil) {
                // show alert
                print("navigate is false, peer is not nil")
                //self.showConnectingAlert = true
                //showConnectingAlert()
                //connectingAlert
            }
        
        })
    }
    
}

struct PeersListView_Previews: PreviewProvider {
    static var previews: some View {
        PeersListView(peerListStore: PeerListStore())
    }
}
