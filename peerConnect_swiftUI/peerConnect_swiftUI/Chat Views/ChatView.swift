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
    @State private var messageText = ""
    //@State private var isSendFile = false
    @State private var showingDocumentPicker = false
    @State private var urlContent : URL?
    @State private var peerStatus = ""
    @State private var messageCount = 0
    @State private var shouldNotifyEndChat = true
    @State var connectedPeersText : String = "none"
    @State var disconnectedPeersText : String = "none"
    @State var groupMembersText : String = "none"
    @State private var shouldDismissChatView = false
    @State private var shouldNavigateToSelectPeer = false
    @Environment(\.colorScheme) var colorScheme
    
    
    var body: some View {
        
        VStack {
            Spacer()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack (alignment: .leading) {
                        ForEach(connectionManager.messageModels, id: \.id) { messageModel in
                            Text(messageModel.whoSaid + ":  " + messageModel.content).id(messageModel.id)
                                .padding([.leading, .trailing], 20)
                        }
                        .padding(0.5)
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                }
                .onChange(of: self.connectionManager.messageModels.count, perform: { _ in
                    guard self.connectionManager.messageModels.count > 0 else { return }
                    withAnimation(Animation.easeInOut) {
                        proxy.scrollTo(self.connectionManager.messageModels.last?.id, anchor: .center)
                        print("scrolled")
                        
                    }
                })
            
            }.navigationBarTitle("Chat View")
            //}//.frame( height: UIScreen.screenHeight*0.35)
            
            TextField("Enter Message: ", text: $messageText, onCommit: {
                print("chat view, send message once ")
                connectionManager.sendMessageToPeers(message: messageText, whoSaid: "Me")
                messageText = ""
            })
            .foregroundColor(Color.black)
            .padding()
            .background(Color.white)
            Spacer()
            PeerStatus(connectedPeersText: self.$connectedPeersText, disconnectedPeersText: self.$disconnectedPeersText,
                       groupMembersText: self.$groupMembersText)
            .background(colorScheme == .dark ? Color(red: 0.09077464789, green: 0.4195016325, blue: 0) : Color(red: 0.7725, green: 0.9412, blue: 0.8157))
            
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    // here we do some cleanings.
                    print("button ending chat")
                    self.resetChatView()
                    self.connectionManager.endChat()
                    self.notifyUserEndChat()
                    // dismiss chat view
                    self.shouldDismissChatView = true
                }) {
                    Text("End Chat")
                        .font(.system(size: 18))
                        .padding()
                        .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0, green: 0.2461058497, blue: 0.5265290141))
                        .overlay(RoundedRectangle(cornerRadius: 15)
                        .stroke(colorScheme == .dark ? Color.white : Color(red: 0, green: 0.2461058497, blue: 0.5265290141), lineWidth: 1))
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
                        .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0, green: 0.2461058497, blue: 0.5265290141))
                        .overlay(RoundedRectangle(cornerRadius: 15)
                        .stroke(colorScheme == .dark ? Color.white : Color(red: 0, green: 0.2461058497, blue: 0.5265290141), lineWidth: 1))
                }
                Spacer()
                
            }  // this is the observer for the navigateToChat value in connection manager,
                // wheneven it is false, dismiss this chat view.
            .onReceive(self.connectionManager.$appState, perform: { appState in
                if ( appState == AppState.endChat) {
                    print("chat view onReceive, detected endChat")
                    if (self.shouldNotifyEndChat) {
                        print("should notify end chat is true")
                        self.connectionManager.endChatState = false
                        self.resetChatView()
                        self.notifyUserEndChat()
                        self.shouldNotifyEndChat = false
                    }
                }
                })
            .onReceive(self.connectionManager.$peersInfo, perform: { peersInfo in
                // here we can also update the peers status below the chat field.
                // update peer status view
                connectionManager.getAppState()
                print("getPeerStatus triggered, for chat view peer info")
                getPeerStatus()
            })
            .onReceive(self.connectionManager.$groupMemberNames, perform: { names in
                getPeerStatus()
            })
            
               
            
        }//.background(Color.blue.edgesIgnoringS afeArea(.top))
        // end of VStack
        //.padding(.bottom, 60)
        Spacer()
        NavigationLink(destination: PeersToSendFileView(urlChosen: self.$urlContent).environmentObject(connectionManager), isActive: $shouldNavigateToSelectPeer) {
            EmptyView()
        }
            .background(colorScheme == .dark ? Color(red: 0.09077464789, green: 0.4195016325, blue: 0) : Color(red: 0.7725, green: 0.9412, blue: 0.8157))
            //present chooser for user to choose file
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(urlChosed: $urlContent)
                //self.getDocumentFromUrl()
            }
            .onAppear() {
                print("chat view appear")
                print("endChatState: \(self.connectionManager.endChatState)")
            }
            .onDisappear() {
                self.connectionManager.endChatState = false
                print("set endChatState onDisappear, to false")
            }
            .onChange(of: urlContent, perform: { content in
                print("got url: \(content)")
                // we check if any document is picked here before we navigate to
                // select peer view.
                if (content != nil) {
                    // get file name and display an alert to confirm
                    self.sendConfirmationAlert()
                    //self.shouldNavigateToSelectPeer = true
                } else {
                    self.notifyUserNilUrlAlert()
                }
            })
        
    }
    
    private func getPeerStatus()  {
        var connectedPeers : [String] = []
        if (connectionManager.isHost) {
            for peerName in connectionManager.groupMemberNames {
                for peer in connectionManager.peersInfo {
                    if (peerName == peer.peerID.displayName && peer.state == PeerState.connected && !connectedPeers.contains(peerName)) {
                        connectedPeers.append(peerName)
                        break  // break out of the first for loop
                    }
                }
            }
             
        } else {
            connectedPeers = [connectionManager.connectedPeer?.displayName ?? ""]
        }
        var disconnectedPeers : [String] = []
        if (connectionManager.isHost) {
            disconnectedPeers.append(contentsOf: connectionManager.getPeerNameStringForState(peerState: PeerState.fromConnectedToDisconnected))
            disconnectedPeers.append(contentsOf: connectionManager.getPeerNameStringForState(peerState: PeerState.fromConnectingToNotConnected))
        } else {
            // here, for the client, there is no peersInfo list checked, the client is always
            // just connected to the host, the disconnected peer is the host.
            disconnectedPeers = [connectionManager.disconnectedPeer?.displayName ?? ""]
        }
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
    
    struct PeerStatus : View {
        
        @Binding var connectedPeersText : String
        @Binding var disconnectedPeersText : String
        @Binding var groupMembersText : String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                //HStack {
                    Text("Connected:  \(self.connectedPeersText)" )
                    .padding([.top, .leading, .trailing], 25)
                    .frame(maxWidth: UIScreen.screenWidth, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                    Spacer()
                    Text("Disconnected:  \(self.disconnectedPeersText)")
                    .padding([.top, .leading, .trailing], 25)
                    .frame(maxWidth: UIScreen.screenWidth, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                    Spacer()
                    Text("Group members:  \(self.groupMembersText)")
                    .padding([.top, .leading, .trailing], 25)
                    .frame(maxWidth: UIScreen.screenWidth, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                    Spacer()
            }
        }
    }

    private func resetChatView()  {
        self.peerStatus = ""
        // clear message model list here
        // it might be bad to clean messages here.
        // it should be cleared from connection manager
    }
    
    private func notifyUserEndChat() {
        
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
        //endChatAlert
        
        endChatAlert.addAction(UIAlertAction(title: "Stay in Chat View", style: .default) {
            _ in
        })
        // here, clicking ok won't dismiss the alert
        //endChatAlert.actions[0].isEnabled = false
        window.rootViewController?.present(endChatAlert, animated: true)
    }
    
    private func getDocumentFromUrl() {
        print("document: \(self.urlContent)")
        // display a list of peers connected for user to choose to send the file.
        self.shouldNavigateToSelectPeer = true
    }
    
    private func notifyUserNilUrlAlert() {
        
        guard let window = UIApplication.shared.keyWindow else {
            return }
        
        let urlNilAlert = UIAlertController(title: "No Document is chosen", message: "There is no document chosen to send.  Please try again.", preferredStyle: .alert)
        
        urlNilAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            print("confirmed")
        })
        
        window.rootViewController?.present(urlNilAlert, animated: true)
    }
    
    private func sendConfirmationAlert() {
        
        guard let window = UIApplication.shared.keyWindow else {
            return }
        
        let sendAlert = UIAlertController(title: "Send Confirmation", message: "Do you want to send the file?", preferredStyle: .alert)
        
        sendAlert.addAction(UIAlertAction(title: "Send", style: .default) { _ in
            print("confirmed")
            self.shouldNavigateToSelectPeer = true
        })
        
        sendAlert.addAction(UIAlertAction(title: "Cancel", style: .default) {
            _ in
            // clear url here
            
        })

        window.rootViewController?.present(sendAlert, animated: true)
    }
    
    //private func
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
    @State static var show : Bool = false
    static var previews: some View {
        ChatView().environmentObject(ConnectionManager())
    }
}
/*
 if let fileContents = try? String(contentsOf: self.urlContent!) {
     print("file contents, from contentsOf: \(fileContents)")
 //} else {
 }
 
 Button(action: {
     getDocumentFromUrl()
     //isSendFile = true
     // should
     //connectionManager.sendFile(peer: connectionManager.connectedPeer!)
 }) {
     Text("get file url")
         .font(.system(size: 18))
         .padding()
         .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0, green: 0.2461058497, blue: 0.5265290141))
         .overlay(RoundedRectangle(cornerRadius: 15)
         .stroke(colorScheme == .dark ? Color.white : Color(red: 0, green: 0.2461058497, blue: 0.5265290141), lineWidth: 1))
 }
 Spacer()
 */
