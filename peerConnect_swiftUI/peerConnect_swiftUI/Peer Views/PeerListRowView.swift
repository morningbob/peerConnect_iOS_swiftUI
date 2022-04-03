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
    // this binding is to pass the peer chosen to Peers List View.
    @Binding var chosenPeer: PeerModel?
    @State private var showConnectingAlert : Bool = false
    
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
        .alert("Connecting to ", isPresented: $showConnectingAlert, actions: {
                
                })
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
