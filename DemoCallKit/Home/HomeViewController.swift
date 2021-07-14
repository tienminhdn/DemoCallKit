//
//  HomeViewController.swift
//  DemoCallKit
//
//  Created by T.Minh on 7/6/21.
//

import UIKit
import SkyWay
import CallKit
import AVFoundation

class HomeViewController: UIViewController {
    
    private var peer: SKWPeer?
    private var dataConnection: SKWDataConnection?
    private var mediaConnection: SKWMediaConnection?
    private var localStream: SKWMediaStream?
    private var remoteStream: SKWMediaStream?
    
    var viewModel = HomeViewModel()
    
    // MARK: - IBOutlets
    @IBOutlet private weak var tableView: UITableView!
    
    let callCenter = CallCenter(supportsVideo: false)
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        callCenter.EndCall()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setup()
    }
    
    @IBAction func getList(_ sender: UIButton) {
        guard let peer = self.peer else { return }
        viewModel.loadConnectedPeerIds(peer: peer)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Private func
    private func configTableView() {
        let nib = UINib(nibName: "PeerCell", bundle: .main)
        tableView.register(nib, forCellReuseIdentifier: "PeerCell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func connect(targetPeerId: String) {
        let options = SKWConnectOption()
        options.serialization = SKWSerializationEnum.SERIALIZATION_BINARY
        if let dataConnection = peer?.connect(withId: targetPeerId, options: options) {
            self.dataConnection = dataConnection
            self.setupDataConnectionCallbacks(dataConnection: dataConnection)
        } else {
            print("failed to connect data connection")
        }
    }
}

// MARK: - Exts
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfrowInsection()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeerCell", for: indexPath) as! PeerCell
        cell.viewModel = viewModel.viewModelForCell(at: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = CallViewController()
       let peerId = viewModel.listPeerID[indexPath.row]
        self.callCenter.StartCall(true)
        print(peerId)
        self.connect(targetPeerId: peerId)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

extension HomeViewController {
    func setup(){
        let option: SKWPeerOption = SKWPeerOption.init();
        option.key = AppDelegate.shared.skywayAPIKey
        option.domain = AppDelegate.shared.skywayDomain
        peer = SKWPeer(options: option)
        guard let peer = peer else { return }
        setupPeerCallBacks(peer: peer)
    }
}

extension HomeViewController {
    func setupPeerCallBacks(peer:SKWPeer) {
        peer.on(SKWPeerEventEnum.PEER_EVENT_OPEN) { obj in
            if let peerId = obj as? String{
                print("your peerId: \(peerId)")
            }
        }
    }
    func setupDataConnectionCallbacks(dataConnection:SKWDataConnection) {
        dataConnection.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_OPEN) { obj in}
        
        dataConnection.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_CLOSE) { obj in
            print("close data connection")
            self.dataConnection = nil
            self.callCenter.EndCall()
        }
    }
}
