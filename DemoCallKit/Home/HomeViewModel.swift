//
//  HomeViewModel.swift
//  DemoCallKit
//
//  Created by T.Minh on 7/6/21.
//

import Foundation
import SkyWay
import Combine

final class HomeViewModel {
    
    // MARK: - Peroperties
    var listPeerID: [String] = []
    fileprivate var peer: SKWPeer?
    // MARK: - Public func
    func numberOfrowInsection() -> Int {
        return listPeerID.count
    }
    
    func viewModelForCell(at indexPath: IndexPath) -> PeerCellViewModel {
        let item = listPeerID[indexPath.row]
        let viewModel = PeerCellViewModel(peerID: item)
        return viewModel
    }
    
    func loadConnectedPeerIds(peer: SKWPeer) {
        peer.listAllPeers { [weak self ] (peerIDs) in
            guard let this = self else { return }
            if let listPeer = peerIDs as? [String] {
                this.listPeerID = listPeer
            }
        }
    }
}
