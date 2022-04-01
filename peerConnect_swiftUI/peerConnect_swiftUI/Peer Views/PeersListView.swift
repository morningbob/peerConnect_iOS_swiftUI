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
    @State var isStartChat = false
    
    init(peerListStore: PeerListStore = PeerListStore()) {
        self.peerListStore = peerListStore
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List(connectionManager.peerModels) { peerModel in
                    PeerListRowView(peerModel: peerModel)
                }.environmentObject(connectionManager)
                Spacer()
                Button(action: { isStartChat = true }) {
                    Text("Start Chat")
                        .font(.system(size: 18))
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 1))
                }
                Spacer()
            }
        }
        .background(Color(red: 0.7725, green: 0.9412, blue: 0.8157))
    }
}

struct PeersListView_Previews: PreviewProvider {
    static var previews: some View {
        PeersListView(peerListStore: PeerListStore())
    }
}
