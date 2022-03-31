//
//  ChatMenuView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-31.
//

import SwiftUI

struct ChatMenuView: View {
    @State var isStartChat = false
    @EnvironmentObject var connectionManager : ConnectionManager
    
    var body: some View {
        NavigationView {
        VStack {
            NavigationLink(destination: ChatView().environmentObject(connectionManager), isActive: $isStartChat) {
            Button(action: { isStartChat = true }) {
                Text("Start a chat session")
                    .font(.system(size: 18))
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue, lineWidth: 1))
            }
            
            }
        }
        }
        .navigationTitle("Chats")
        .background(Color(red: 0.7725, green: 0.9412, blue: 0.8157))
        
    }
}

struct ChatMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ChatMenuView()
    }
}
