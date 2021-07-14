//
//  PeerCell.swift
//  DemoCallKit
//
//  Created by T.Minh on 7/6/21.
//

import UIKit

class PeerCell: UITableViewCell {
    
    @IBOutlet private weak var peerIDLabel: UILabel!
    
    var viewModel: PeerCellViewModel! {
        didSet {
            updateUI()
        }
    }
    
    func updateUI() {
        peerIDLabel.text = viewModel.peerID
    }
}
