//
//  ContentView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-28.
//

import SwiftUI

struct ContentView: View {
    @State var startApp = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Image("peerConnectLogo2").resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .padding(.all, 30.0)
                    Spacer()
                }
                Text("The app provides peer communication with nearby devices.  It uses bluetooth and WiFi to discover nearby devices and send messages and files to and from them.  The user can communicate with multiple peers at the same time.   The communication is entirely local.  There is no centralized server.  ")
                    .multilineTextAlignment(.center)
                    .padding( [.leading, .trailing], 50.0)
                    .font(.system(size: 18))
                    .navigationBarTitle("Peer Connect", displayMode: .inline)
                    
                Spacer()
                HStack {
                    Spacer()
                    NavigationLink(destination: PeersListView(), isActive: $startApp) {
                   
                        Button(action: {
                            self.startApp = true
                        }) {
                            Text("Scan For Device")
                                .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 0, green: 0.2461058497, blue: 0.5265290141))
                                .padding()
                                .overlay(RoundedRectangle(cornerRadius: 15)
                                .stroke(colorScheme == .dark ? Color.white : Color(red: 0, green: 0.2461058497, blue: 0.5265290141), lineWidth: 1))
                        }}
                        .padding(.all, 30)
                    Spacer()
                }
                Spacer()
            }
            .background(colorScheme == .dark ? Color(red: 0.09077464789, green: 0.4195016325, blue: 0) : Color(red: 0.7725, green: 0.9412, blue: 0.8157))
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
