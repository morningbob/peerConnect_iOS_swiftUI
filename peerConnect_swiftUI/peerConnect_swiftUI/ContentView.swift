//
//  ContentView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import SwiftUI

struct ContentView: View {
    @State var isLinkActive = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Image("sampleIcon").resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .padding(.all, 30.0)
                    Spacer()
                }
                Text("The app provides peer communication with nearby devices.  It uses bluetooth and WiFi to discover nearby devices and send messages and files to and from them.  The user can communicate with multiple peers at the same time.   The communication is entirely local.  There is no centralized server.  ")
                    .padding( [.leading, .trailing], 50.0)
                    
                    .font(.system(size: 18))
                    .navigationBarTitle("Peer Connect", displayMode: .inline)
                HStack {
                    Spacer()
                    NavigationLink(destination: PeersListView(), isActive: $isLinkActive) {
                    Button(action: {
                        self.isLinkActive = true
                    }) {
                        Text("Start")
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue, lineWidth: 1))
                           
                    }}
                    .padding(.all, 40)
                    Spacer()
                }
                Spacer()
            }
            .background(Color(red: 0.7725, green: 0.9412, blue: 0.8157))
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewInterfaceOrientation(.portrait)
            
        }
    }
}
