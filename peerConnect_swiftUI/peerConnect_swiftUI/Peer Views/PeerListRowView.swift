//
//  PeerListRowView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import SwiftUI
/*
struct PeerListRowView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    //let peerModel: PeerModel
    //let peerCheckListItem: PeerCheckListItem
    //var peerCheckListItems: [PeerCheckListItem]
    // this binding is to pass the peer chosen to Peers List View.
    @Binding var chosenPeer: PeerModel?
    @State private var showConnectingAlert : Bool = false
    //@State var appState
    @State var selectedPeer = false
    
    
    var body: some View {
        
        HStack {
            //Toggle(peerModel.name, isOn: $selectedPeer).toggleStyle(.button)
            //Toggle(peerCheckListItem.peerModel.name, isOn: peerCheckListItem.$isChecked).toggleStyle(SwitchToggleStyle(tint: .yellow))
            //Text(peerModel.name)
            //Image(systemName: checked ? "checkmark.square.fill" : "sqaure")
            // this spacer is to use to cover the whole row area such that
            // the user can tap anywhere in the row to trigger onTapGesture
            //Text(peerCheckListItem.peerModel.name)
            Spacer()
            //Text(peerCheckListItem.isChecked ? "✅" : "🔲")
        }
        // contentShape is to set the whole row area as can be tapped.
        .contentShape(Rectangle())
        .onTapGesture {
            if let checkedIndex =
                self.peerCheckListItems.firstIndex(where: { $0.id == peerCheckListItem.id }) {
                self.peerCheckListItems[checkedIndex].isChecked.toggle()
            }
            // pass peer view model to List View
            print("set peer in row view")
            self.chosenPeer = peerCheckListItem.peerModel
            connectionManager.inviteConnect(peerModel: self.chosenPeer!)
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
 */
