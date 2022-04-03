//
//  PeerListRowView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import SwiftUI

struct PeerListRowView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    let peerModel: PeerModel
    //@State var isChat = false
    //@State var toNavigate = false
    @Binding var chosenPeer: PeerModel?
    
    var body: some View {
        
        HStack {
            Text(peerModel.name)
        }.onTapGesture {
            //connectionManager.inviteConnect(peerModel: peerModel)
            // pass peer view model to List View
            print("set peer in row view")
            //self.chosenPeer = peerModel
            connectionManager.inviteConnect(peerModel: peerModel)
        }
        
        
        /*
        NavigationLink(destination:
                        ChatView().environmentObject(connectionManager),
                       isActive: $connectionManager.navigateToChat) {
            HStack {
                Text(peerModel.name)
            }.onTapGesture {
                //connectionManager.inviteConnect(peerModel: peerModel)
                // pass peer view model to List View
                self.chosenPeer = peerModel
            }
         */
            /*
                        PeerView(peerModel: peerModel)) {
            HStack {
                Text(peerModel.name)
            }.onTapGesture {
                connectionManager.inviteConnect(peerModel: peerModel)
                
            }
        }.environmentObject(connectionManager)
        */
        //}//.background(Color(red: 0.7725, green: 0.9412, blue: 0.8157))
    }
}

struct PeerListRowView_Previews: PreviewProvider {
    //@State var chosen: PeerModel?
    @Binding var peer : PeerModel?
    
    //static var previews: some View {
    //    PeerListRowView(  peerModel: PeerModel(name: "Kind"), chosenPeer: $peer).environmentObject(ConnectionManager())
    //}
    static var previews: some View {
        StatefulPreviewWrapper(false) { _ in ContentView() }
        }
}

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    var body: some View {
        content($value)
    }

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(wrappedValue: value)
        self.content = content
    }
}
