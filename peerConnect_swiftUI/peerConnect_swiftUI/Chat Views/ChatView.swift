//
//  ChatView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie on 2022-03-29.
//

import SwiftUI
import MultipeerConnectivity

struct ChatView: View {
    @EnvironmentObject var connectionManager : ConnectionManager
    
    @State private var messageText = ""
    //let peerID : MCPeerID
    
    var body: some View {
        
        VStack {
            Text("Chat View")
            List(connectionManager.messageModels) {
                messageModel in
                Text(messageModel.whoSaid + ":  " + messageModel.content)
                
            }.environmentObject(connectionManager)
                .frame( height: 300)
            TextField("Enter Message: ", text: $messageText, onCommit: {
                      guard !messageText.isEmpty else { return }
                connectionManager.sendMessage(messageText, to: connectionManager.connectedPeer!)
                messageText = ""
            })
            Spacer()
        }
        
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView().environmentObject(ConnectionManager())
    }
}
