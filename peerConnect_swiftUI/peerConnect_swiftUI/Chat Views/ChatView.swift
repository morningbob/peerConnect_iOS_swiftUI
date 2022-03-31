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
    @Environment(\.presentationMode) var presentation
    
    @State var messageText = ""
    //@State var isEndChat = false //{
        //didSet {
        //    if (isEndChat == true) {
        //        self.presentation.wrappedValue.dismiss()
        //    }
        //}
    //}
    
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
            .padding()
            Spacer()
            //NavigationLink(destination: PeersListView(), isActive: $isEndChat) {
            VStack {
                Button(action: {
                    //isEndChat = true
                    connectionManager.endChat()
                    print("ending chat")
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Text("End Chat")
                        .font(.system(size: 18))
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 1))
                }
                Spacer()
            }
            //}
        }.background(Color(red: 0.7725, green: 0.9412, blue: 0.8157))
        
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView().environmentObject(ConnectionManager())
    }
}
