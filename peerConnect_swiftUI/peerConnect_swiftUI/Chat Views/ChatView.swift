//
//  ChatView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie on 2022-03-29.
//

import SwiftUI
import MultipeerConnectivity
//import NavigationViewKit

struct ChatView: View {
    @EnvironmentObject var connectionManager : ConnectionManager
    @Environment(\.presentationMode) var presentation
    @State private var messageText = ""
    //@State private var isSendFile = false
    @State private var showingDocumentPicker = false
    @State private var urlContent = UrlContent()
    @State private var peerStatus = ""
    //@Environment(\.navigationManager) var nvmanager
    
    var body: some View {
        
        VStack {
            Text("Chat View")
            List(connectionManager.messageModels) {
                messageModel in
                Text(messageModel.whoSaid + ":  " + messageModel.content)
                
            }.environmentObject(connectionManager)
                .frame( height: 300)
            TextField("Enter Message: ", text: $messageText, onCommit: {
                print("chat view, send message once ")
                connectionManager.sendMessageToPeers(message: messageText, whoSaid: "Me")
                messageText = ""
            })
            .padding()
            .background(Color.white)
            Spacer()
            PeerStatus(connectionManager: self.connectionManager)
                .background(Color(red: 0.7725, green: 0.9412, blue: 0.8157))
                //.frame(alignment: .leading)
            
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    connectionManager.endChat()
                    print("ending chat")
                    // reset isHost, no longer to be the host
                    connectionManager.isHost = false
                    connectionManager.endChatState = true
                    // show alert of chat ending
                    guard let window = UIApplication.shared.keyWindow else {
                            return }
                    let endChatAlert = UIAlertController(title: "Chat ended", message: "The app ended the chat.  All peers disconnected.", preferredStyle: .alert)
                    
                    endChatAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        // end the chat
                        print("confirmed")
                        // already disconnected the peers above
                        // clear list and peers status here
                        self.resetChatView()
                        // dismiss chat view
                        self.presentation.wrappedValue.dismiss()
                    })
                    endChatAlert.addAction(UIAlertAction(title: "Stay in Chat View", style: .default) {
                        _ in
                        // don't dismiss the chat view
                    })
                    DispatchQueue.main.async {
                        window.rootViewController?.present(endChatAlert, animated: true)
                    }
                }) {
                    Text("End Chat")
                        .font(.system(size: 18))
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 1))
                }
                Spacer()
                // add navigation link here later
                Button(action: {
                    showingDocumentPicker = true
                    //isSendFile = true
                    // should
                    //connectionManager.sendFile(peer: connectionManager.connectedPeer!)
                }) {
                    Text("Send File")
                        .font(.system(size: 18))
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 1))
                }
                Spacer()
                Button(action: {
                    getDocumentFromUrl()
                    //isSendFile = true
                    // should
                    //connectionManager.sendFile(peer: connectionManager.connectedPeer!)
                }) {
                    Text("get file url")
                        .font(.system(size: 18))
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 1))
                }
                Spacer()
                
                
            }  // this is the observer for the navigateToChat value in connection manager,
                // wheneven it is false, dismiss this chat view.
            .onReceive(connectionManager.$appState, perform: { appState in
                //if (appState == AppState.normal || appState == AppState.endChat) {
                //    self.presentation.wrappedValue.dismiss()
                //}
            })
            .onReceive(connectionManager.$peersInfo, perform: { peersInfo in
                // here we can also update the peers status below the chat field.
                // update peer status view
                connectionManager.getAppState()
            })
            
            
        }
        .padding(.bottom, 120)
        Spacer()
            .background(Color(red: 0.7725, green: 0.9412, blue: 0.8157))
            //present chooser for user to choose file
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(urlChosed: $urlContent.url)
                //self.getDocumentFromUrl()
            }
        /*
            .onAppear() {
                if (self.inputUrl != nil) {
                    print("inputUrl is not null")
                    getDocumentFromUrl()
                } else {
                    print("nothing in inputUrl")
                }
            }
         */
    }
    
    struct PeerStatus : View {
        
        @ObservedObject var connectionManager : ConnectionManager
        
        @State var connectedPeersText : String = "none"
        @State var disconnectedPeersText : String = "none"
        @State var groupMembersText : String = "none"
        
        var body: some View {
            VStack(alignment: .leading, spacing: 3) {
                //HStack {
                    Text("Connected:  \(self.connectedPeersText)" )
                    .padding(25)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Text("Disconnected:  \(self.disconnectedPeersText)")
                    .padding(25)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Text("Group members:  \(self.groupMembersText)")
                    .padding(25)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    //Text()
                    
                //}
            }.onReceive(connectionManager.$peersInfo, perform: { peersInfo in
                print("getPeerStatus triggered")
                getPeerStatus()
            })
            .onReceive(connectionManager.$groupMemberNames, perform: { names in
                getPeerStatus()
            })
            
        }
            
        
        private func getPeerStatus()  {
            var connectedPeers = connectionManager.getPeerNameStringForState(peerState: PeerState.connected)
            var disconnectedPeers = connectionManager.getPeerNameStringForState(peerState: PeerState.fromConnectedToDisconnected)
            var connectedText = ""
            for peer in connectedPeers {
                connectedText += peer + "   "
            }
            if connectedText == "" {
                connectedText = "none"
            }
            var disconnectedText = ""
            for peer in disconnectedPeers {
                disconnectedText += peer + "   "
            }
            if disconnectedText == "" {
                disconnectedText = "none"
            }
            // assgin to state variables once only for the whole text
            // to avoid too many refresh.
            self.connectedPeersText = connectedText
            self.disconnectedPeersText = disconnectedText
            
            var groupMembers = connectionManager.groupMemberNames
            var groupText = ""
            for member in groupMembers {
                groupText += member + "   "
            }
            self.groupMembersText = groupText
        }
        
    }

    private func resetChatView() {
        self.peerStatus = ""
        // clear message model list here
        // it might be bad to clean messages here.
        // it should be cleared from connection manager
        // when the app state is endChat
        self.connectionManager.clearMessageList()
    }
    
    private func getDocumentFromUrl() {
        print("document: \(self.urlContent.url)")
    }
}

struct UrlContent {
    var url : URL? = nil {
        didSet {
            if url != nil {
                print("url: \(url)")
            }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView().environmentObject(ConnectionManager())
    }
}
