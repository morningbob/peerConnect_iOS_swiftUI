//
//  Constants.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-04-04.
//

import Foundation
import UIKit

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
    case endChat
    case connected
    
}

enum PeerState : Codable {
    case discovered
    case checked
    case connecting
    case fromConnectingToNotConnected
    case fromConnectedToDisconnected
    case connected
    
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}

