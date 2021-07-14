//
//  PeerCellViewModel.swift
//  DemoCallKit
//
//  Created by T.Minh on 7/6/21.
//

import Foundation

final class PeerCellViewModel {
    
    // MARK: - Peroperties
    private(set) var peerID: String
    
    // MARK: -Init
    init(peerID: String) {
        self.peerID = peerID
    }
}
