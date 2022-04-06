//
//  Constants.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-04-04.
//

import Foundation

enum ConnectionState {
    case connected
    case notConnected
    case connecting
    case listening
}

enum AppState : Codable {
    case normal
    case connecting
    case fromConnectingToNotConnected  // peer rejected
    case fromConnectedToDisconnected   // user ends chat
    case chatting
    case startChat
    case connected
    
}

