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
    @State private var urlContent = UrlContent()
    /*
    @State var inputUrl: URL? {
        didSet {
            print("inputUrl didSet triggered")
            self.getDocumentFromUrl()
        }
    }
    */
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
            .background(Color.white)
            Spacer()
            VStack {
                Button(action: {
                    connectionManager.endChat()
                    print("ending chat")
                    // pop this view
                    //self.presentation.wrappedValue.dismiss()
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
            .onReceive(connectionManager.$navigateToChat, perform: { navigateToChat in
                if (!navigateToChat) {
                    self.presentation.wrappedValue.dismiss()
                }
            })
            //.onReceive(Just(inputUrl), perform: { url in
                
            //})
        }
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
