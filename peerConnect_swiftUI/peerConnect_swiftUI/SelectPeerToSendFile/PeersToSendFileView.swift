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
    @State var sendFileSuccess : [String : Bool] = [:]
    @State var sendFileStatus : String = ""
    
    var body: some View {
        // List of connected peers in the chat
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
        VStack {
            Spacer()
            Text("File: \(urlChosen?.lastPathComponent ?? "No file is chosen.")")
            Text(self.sendFileStatus)
                .padding()
            Spacer()
            Button(action: {
                 
                if (urlChosen == nil) {
                    // alert user
                    self.notifyUserNilUrlAlert()
                } else {
                    print("sending starts")
                    self.connectionManager.sendFileToPeers(peersInfo: self.checkedpeers, urlChosen: urlChosen!)
                    //self.getSendStatus(sendDict: self.sendFileSuccess)
                }
                
            }) { Text("Send")
            }
            .font(.system(size: 18))
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(Color.blue, lineWidth: 1))
            .background(Color(red: 0.7725, green: 0.9412, blue: 0.8157))
            Spacer()
            
        }
        
        .onReceive(self.connectionManager.$peersInfo, perform: { peersInfo in
            print("onReceive is triggered.")
            self.checkedpeers = peersInfo.filter({
                $0.sendFileTo
            })
            print("total number of peers checked \(self.checkedpeers.count)")
        })
        .onChange(of: self.urlChosen, perform: { url in
            print("url got from chat view: \(url)")
        })
        .onReceive(self.connectionManager.$sendFileSuccessDict, perform: { dict in
            self.getSendStatus(sendDict: dict)
        })
        
    }
    
    private func getSendStatus(sendDict: [String:Bool]) {
        self.sendFileStatus = ""
        for (key, value) in sendDict {
            var success = value ? "success" : "failure"
            self.sendFileStatus += "\(key):  \(success)    "
            print("total send files count: \(self.sendFileStatus.count)")
        }
        if (self.sendFileStatus.count == self.checkedpeers.count) {
            print("file sent")
            // display alert of file sent
            self.fileSentAlert()
        }
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
    
    static var previews: some View {
        PeersToSendFileView(urlChosen: self.$url)
    }
}
