//
//  PeersToSendFileView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-05-16.
//

import SwiftUI

struct PeersToSendFileView: View {
    
    @EnvironmentObject var connectionManager : ConnectionManager
    @State var checkedpeers : [PeerInfo] = []
    @Binding var urlChosen : URL?
    @State var sendFileStatus : String = ""
    @Environment(\.colorScheme) var colorScheme
    @State var fileName = ""
    @State var sendingState = SendFileState.notSending
    @Environment(\.presentationMode) var presentation
    
    
    var buttonBack : some View {
        Button(action: {
            print("will dismiss sending view here ****************************")
            self.clearSentCommentsAndContent()
            self.presentation.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "arrow.left.circle")
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.blue)
                Text("Chat View")
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.blue)
            }
        }
    }
    
    var body: some View {
        // List of connected peers in the chat
        VStack {
        Spacer()
        Text("Please choose the peers to send the file to:")
            .padding()
        Spacer()
        List(self.connectionManager.peersInfo, id: \.id){ peerInfo in
            PeerRowView(peerInfo: peerInfo, sendTo: true)
                .onTapGesture {
                    if let checkedIndex =
                        self.connectionManager.peersInfo.firstIndex(where: { $0.id == peerInfo.id }) {
                        self.connectionManager.peersInfo[checkedIndex].sendFileTo.toggle()
                        // this is for triggering the change of peersInfo
                        let peer = self.connectionManager.peersInfo[checkedIndex]
                        self.connectionManager.peersInfo[checkedIndex] = peer
                        print("modified peer")
                    }
                }
        }
        //HStack {
        VStack {
            Spacer()
            Text((self.urlChosen?.lastPathComponent ?? self.fileName))
            Text(self.sendFileStatus)
                .padding()
            Spacer()
            Text(getSendText())
            Spacer()
            Button(action: {
                 
                if (urlChosen == nil) {
                    // alert user
                    print("send button: nil url")
                    self.notifyUserNilUrlAlert()
                } else if (self.checkedpeers.isEmpty) {
                    print("no peer is chosen")
                    self.noPeerChosenAlert()
                } else {
                    print("sending starts")
                    self.sendingState = SendFileState.sending
                    self.connectionManager.sendFileToPeers(peersInfo: self.checkedpeers, urlChosen: urlChosen!)
                }
                
            }) { Text("Send")
            }
            .font(.system(size: 18))
            .padding()
            .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0, green: 0.2461058497, blue: 0.5265290141))
            .overlay(RoundedRectangle(cornerRadius: 15)
            .stroke(colorScheme == .dark ? Color.white : Color(red: 0, green: 0.2461058497, blue: 0.5265290141), lineWidth: 1))
            .background(colorScheme == .dark ? Color(red: 0.09077464789, green: 0.4195016325, blue: 0) : Color(red: 0.7725, green: 0.9412, blue: 0.8157))
            Spacer()
            
        }}.background(colorScheme == .dark ? Color(red: 0.09077464789, green: 0.4195016325, blue: 0) : Color(red: 0.7725, green: 0.9412, blue: 0.8157))
        
        
        .onReceive(self.connectionManager.$peersInfo, perform: { peersInfo in
            print("onReceive is triggered.")
            self.checkedpeers = peersInfo.filter({
                $0.sendFileTo
            })
            print("total number of peers checked \(self.checkedpeers.count)")
        })
        .onChange(of: self.urlChosen, perform: { url in
            print("url got from chat view: \(url)")
            if (url != nil) {
                self.fileName = url!.lastPathComponent
            }
        })
        .onReceive(self.connectionManager.$sendFileSuccessDict, perform: { dict in
            self.getSendStatus(sendDict: dict)
        })
        .onChange(of: self.sendingState, perform: { state in
            print("sending state changes")
            print("state: \(state)")
            //if (state == SendFileState.notSending) {
            //    self.sendFileStatus = ""
            //}
        })
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: buttonBack)
        
    }
        
    
    private func getSendStatus(sendDict: [String:Bool]) {
        self.sendFileStatus = ""
        print("sentDict count: \(sendDict.count)")
        var sentCount = 0
        var successCount = 0
        for (key, value) in sendDict {
            var success = value ? "success" : "failure"
            self.sendFileStatus += "\(key):  \(success)    "
            sentCount += 1
            print("total send files count: \(sentCount)")
            if success == "success" {
                successCount += 1
            }
        }
        if (!self.sendFileStatus.isEmpty && sentCount == self.checkedpeers.count) {
            print("cleaning starts")
            if (successCount >= 1) {
                self.sendingState = SendFileState.sentWithSuccess
            } else {
                self.sendingState = SendFileState.sentWithNoSuccess
            }
            // clear previous selection and url
            self.clearSentInfo()
        }
    }
    
    private func getSendText() -> String {
        switch (self.sendingState) {
        case SendFileState.notSending:
            return "Preparing to send."
        case SendFileState.sending:
            return "Sending...."
        case SendFileState.sentWithNoSuccess:
            return "Failed to send the file.  Plesae try again."
        case SendFileState.sentWithSuccess:
            return "File was sent."
        default:
            return "Preparing to send."
        }
    }
    
    // to prevent user to send the same file again accidentally
    private func clearSentInfo() {
        // find the peers from checkedpeers and remove the check
        for peer in self.checkedpeers {
            if let checkedIndex = self.connectionManager.peersInfo.firstIndex(where: { $0.id == peer.id }) {
                // this way, the peersInfo's onChange will be triggered
                var checkedPeer = self.connectionManager.peersInfo[checkedIndex]
                checkedPeer.sendFileTo = false
                self.connectionManager.peersInfo[checkedIndex] = checkedPeer
                print("reset \(peer.peerID.displayName)")
            }
        }
        self.checkedpeers = []
        self.urlChosen = nil
        
    }
    
    private func clearSentCommentsAndContent() {
        self.fileName = ""
        self.sendingState = SendFileState.notSending
        self.connectionManager.sendFileSuccessDict = [:]
        self.checkedpeers = []
    }
    
    
    private func notifyUserNilUrlAlert() {
        
        guard let window = UIApplication.shared.keyWindow else {
            return }
        
        let urlNilAlert = UIAlertController(title: "Choose a document", message: "Please choose a document to send.", preferredStyle: .alert)
        
        urlNilAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            print("confirmed")
        })
        
        window.rootViewController?.present(urlNilAlert, animated: true)
    }
    
    private func noPeerChosenAlert() {
        
        guard let window = UIApplication.shared.keyWindow else {
            return }
        
        let noPeerChosenAlert = UIAlertController(title: "Choose a peer", message: "Please choose a peer to send the file to.", preferredStyle: .alert)
        
        noPeerChosenAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            print("confirmed")
        })
        
        window.rootViewController?.present(noPeerChosenAlert, animated: true)
    }
    
    private func fileSentAlert() {
        
        guard let window = UIApplication.shared.keyWindow else {
            return }
        
        let fileSentAlert = UIAlertController(title: "File Sent", message: "The file is sent.  Please read the details in the bottom of the screen.", preferredStyle: .alert)
        
        fileSentAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            print("confirmed")
        })
        
        window.rootViewController?.present(fileSentAlert, animated: true)
    }
}


struct PeersToSendFileView_Previews: PreviewProvider {
    @State static var url = URL(string: "https://a")
    @State static var sendState = SendFileState.notSending
    
    static var previews: some View {
        PeersToSendFileView(urlChosen: self.$url)
    }
}
