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
    
    var body: some View {
        // List of connected peers in the chat
        Text("Please choose the peers to send the file to:")
        Spacer()
        List(self.connectionManager.peersInfo, id: \.id){ peerInfo in
            PeerRowView(peerInfo: peerInfo)
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
            Text("File: file name.txt")
            Spacer()
            Button(action: {
                for peer in checkedpeers {
                    self.connectionManager.sendFile(peer: peer.peerID, url: urlChosen!)
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
        
    }
}


struct PeersToSendFileView_Previews: PreviewProvider {
    @State static var url = URL(string: "https://a")
    
    static var previews: some View {
        PeersToSendFileView(urlChosen: self.$url)
    }
}
