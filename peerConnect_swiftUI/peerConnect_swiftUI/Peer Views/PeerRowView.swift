//
//  PeerRowView.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-05-16.
//

import SwiftUI

struct PeerRowView : View {
    
    @ObservedObject var peerInfo : PeerInfo
    
    init(peerInfo: PeerInfo) {
        self.peerInfo = peerInfo
    }
    
    var body: some View {
    
        HStack {
            // this spacer is to use to cover the whole row area such that
            // the user can tap anywhere in the row to trigger onTapGesture
            Text(peerInfo.peerID.displayName)
            Spacer()
            Text(peerInfo.isChecked ? "✅" : "🔲")
            //Text("isCheck \(String(peerInfo.isChecked))")
        }
    }
}


