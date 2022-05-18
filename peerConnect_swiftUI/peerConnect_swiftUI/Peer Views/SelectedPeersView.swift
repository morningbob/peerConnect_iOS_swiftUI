//
//  SelectedPeersView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-04-08.
//

import SwiftUI

struct SelectedPeersView: View {
    
    @EnvironmentObject var connectionManager : ConnectionManager
    @State private var shouldNavigateToChat = false
    @Environment(\.presentationMode) var presentation
    @State private var appStateHistory : [AppState] = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        VStack {
            // here we input the peersInfo which are selected
            List(self.connectionManager.peersInfo) { peerInfo in
                // we do the selection here
                if (peerInfo.isChecked) {
                    PeerStatusView(peerInfo: peerInfo)
                }
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
                    .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0, green: 0.2461058497, blue: 0.5265290141))
                    .overlay(RoundedRectangle(cornerRadius: 15)
                    .stroke(colorScheme == .dark ? Color.white : Color(red: 0, green: 0.2461058497, blue: 0.5265290141), lineWidth: 1))
            }.background(colorScheme == .dark ? Color(red: 0.09077464789, green: 0.4195016325, blue: 0) : Color(red: 0.7725, green: 0.9412, blue: 0.8157))
                .padding(.top, 20)
            Spacer()
        }
        //.background(Color(red: 0.7725, green: 0.9412, blue: 0.8157))
        .background(colorScheme == .dark ? Color(red: 0.09077464789, green: 0.4195016325, blue: 0) : Color(red: 0.7725, green: 0.9412, blue: 0.8157))
        
        .onReceive(self.connectionManager.$peersInfo, perform: { peersInfo in
            // verified, here, we can observe states changed
            print("selected peers view, peersInfo changed")
            
            
            self.connectionManager.getAppState()
        })
        .onReceive(self.connectionManager.$appState, perform: { state in
            // keep a history of app states here
            // if the app state is the same with the previous state
            // we neglect it
            if (state != self.appStateHistory.last) {
                self.appStateHistory.append(state)
                print("added \(state) state")
            }
            //print("added new app state \(state)")
            if (state == AppState.connected) {
                self.shouldNavigateToChat = true
                print("appState changed to connected, navigate to chat")
            }
        })
        // here, we check if all the peers rejected the chat
        // we'll show an alert to user
        // one way to detect if all peers reject the chat is to
        // see if the app state goes from connecting to end chat.
        .onChange(of: self.appStateHistory, perform: { history in
            print("detected app state history changed")
            print("size of history: \(self.appStateHistory.count)")
            for state in self.appStateHistory {
                print("state: \(state)")
            }
            print("end of history")
            //var previousState = AppState.normal
            var disconnectedState = false
            for state in self.appStateHistory {
                if (state == AppState.disconnected || state == AppState.normal) {
                    //previousState = state
                    disconnectedState = true
                } else if (state == AppState.endChat) {
                    //if (previousState == AppState)
                    if (disconnectedState) {
                        //rejectCount += 1
                        print("reject detected")
                        // clear history here
                        self.appStateHistory = []
                        // notify user of chat ends
                        self.peerRejectionAlert()
                        break
                    }
                    
                } else {
                    disconnectedState = false
                }
            }
        })
        .onAppear() {
            self.connectionManager.getAppState()
            if (self.connectionManager.appState == AppState.endChat) {
                print("endChat detected, from onAppear selectedPeerView, dismissing")
                self.presentation.wrappedValue.dismiss()
            }
            
        }
        .navigationTitle("Peers Status")
        NavigationLink(destination: ChatView().environmentObject(connectionManager), isActive: $shouldNavigateToChat) {
            EmptyView()
        }
    }
    
    private func peerRejectionAlert() {
        // alert user to choose a peer
        guard let window = UIApplication.shared.keyWindow else {
                return }
        let peerRejectionAlert = UIAlertController(title: "No peer accepted chat", message: "There is no peer accepted the chat.  The chat is dismissed.", preferredStyle: .alert)
        
        peerRejectionAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            print("confirmed")
            self.presentation.wrappedValue.dismiss()
        })
        
        DispatchQueue.main.async {
            window.rootViewController?.present(peerRejectionAlert, animated: true)
        }
    }
}

struct SelectedPeersView_Previews: PreviewProvider {
    @State static var showPeerStatus : Bool = false
    static var previews: some View {
        SelectedPeersView()
    }
}

struct PeerStatusView : View {
    
    @ObservedObject var peerInfo : PeerInfo
    
    init(peerInfo: PeerInfo) {
        self.peerInfo = peerInfo
    }
    
    var body: some View {
        HStack {
            
            Text(peerInfo.peerID.displayName + ":  " + getNewStatus())
            Text(peerInfo.state == PeerState.connected ? "    ✅" : "    🔲")
        }
       
    }
    
    private func getNewStatus() -> String {
        var status = ""
        switch (peerInfo.state) {
        case PeerState.connecting:
            status = "Connecting..."
        case PeerState.fromConnectingToNotConnected:
            status = "Peer refused connection."
        case PeerState.fromConnectedToDisconnected:
            status = "Peer disconnected."
        case PeerState.connected:
            status = "Peer connected."
        default:
            status = "Connecting..."
        }
        return status
    }
}



/*
 let navigateBinding = Binding<Bool> (
     get: {
         //print("binding executed")
         return self.connectionManager.appState == AppState.connected },
     
     set: {_ in
         if self.connectionManager.appState == AppState.connected {
             self.shouldNavigateToChat = true
             //print("binding set true")
         } else {
             self.shouldNavigateToChat = false
             //print("binding set false")
         }
     })
 */

