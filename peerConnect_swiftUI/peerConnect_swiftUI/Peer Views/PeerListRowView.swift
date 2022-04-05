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
    //@State var appState 
    
    var body: some View {
        
        HStack {
            Text(peerModel.name)
            // this spacer is to use to cover the whole row area such that
            // the user can tap anywhere in the row to trigger onTapGesture
            Spacer()
        }
        // contentShape is to set the whole row area as can be tapped.
        .contentShape(Rectangle())
        .onTapGesture {
            // pass peer view model to List View
            print("set peer in row view")
            self.chosenPeer = peerModel
            connectionManager.inviteConnect(peerModel: peerModel)
            self.showConnectingAlert = true
            
        }/*
        .alert("Connecting to ", isPresented: Binding(
            get: {
                print("binding executed connecting true")
                
                return connectionManager.connectionState == ConnectionState.connecting },
            set: { _,_ in if (connectionManager.connectionState == ConnectionState.connecting) {
                print("connecting true")
                //$0 = true
            }} ), actions: {})
          */
        .alert("Connecting to ", isPresented: $showConnectingAlert, actions: {
                
                })
        // when navigating to chat view, the alert will stay across views
        // so we need to dismiss it manually.
        .onDisappear() {
            self.showConnectingAlert = false
        }
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
