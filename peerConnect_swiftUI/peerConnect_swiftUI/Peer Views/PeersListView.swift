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
    //@State var isStartChat = false
    //@State var startChat = false
    //@State private var selection : String? = nil
    //@State private var ready : Bool?
    
    // this is the case when the user starts a chat, peer will not be nil
    @State var peer : PeerModel?
    
    
    /*{
        didSet {
            print("peer didSet ran")
            if peer != nil {
                print("peer didSet triggered and not nil")
                connectionManager.inviteConnect(peerModel: peer!)
            }
        }
     
    }
     */
    
    init(peerListStore: PeerListStore = PeerListStore()) {
        self.peerListStore = peerListStore
        //connectionManager.navigateToChat 
    }
    // tag: "Chat", selection: $selection)
    var body: some View {
        //NavigationView {
        
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
                NavigationLink(destination: ChatView().environmentObject(connectionManager), isActive: $connectionManager.navigateToChat)  {
                    //.environmentObject(connectionManager)
                    EmptyView()
                }
        //}
        
    }
}

struct PeersListView_Previews: PreviewProvider {
    static var previews: some View {
        PeersListView(peerListStore: PeerListStore())
    }
}
