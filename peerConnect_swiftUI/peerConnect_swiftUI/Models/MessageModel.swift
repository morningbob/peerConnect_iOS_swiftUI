//
//  Message.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-03-30.
//

import Foundation

struct MessageModel : Codable, Identifiable {
    
    var id = UUID()
    let content : String
    let peerName : String
    let whoSaid : String
    var time = Date()
}
