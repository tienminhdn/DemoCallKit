//
//  CallViewController.swift
//  DemoCallKit
//
//  Created by T.Minh on 7/5/21.
//

import UIKit
import SkyWay
import CallKit
import AVFoundation

class CallViewController: UIViewController {
    
    private var peer: SKWPeer?
    private var dataConnection: SKWDataConnection?
    private var mediaConnection: SKWMediaConnection?
    private var localStream: SKWMediaStream?
    private var remoteStream: SKWMediaStream?
    
    // MARK: - IBOutlets
    @IBOutlet private weak var remoteView: SKWVideo!
    @IBOutlet private weak var localView: SKWVideo!
    @IBOutlet private weak var endCallButton: UIButton!
    @IBOutlet private weak var videoButton: UIButton!
    @IBOutlet private weak var voiceButton: UIButton!
    @IBOutlet private weak var switchCameraButton: UIButton!
    
    
    // MARK: - Peroperties
    var peerID: String?
    var isChangeVoice: Bool = false
    var isChangVideoCall: Bool = false
    var isSwitchCamera: Bool = false
    let callCenter = CallCenter(supportsVideo: true)
    let tabgesTure = UIGestureRecognizer(target: self, action: #selector(tabLocalView))
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        navigationController?.isNavigationBarHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissionAudio()
        callCenter.setup(self)
        setup()
    }

    
    // MARK: - Private func
    private func configUI() {
        switchCameraButton.layer.cornerRadius = switchCameraButton.frame.height / 2
        videoButton.layer.cornerRadius = switchCameraButton.frame.height / 2
        voiceButton.layer.cornerRadius = switchCameraButton.frame.height / 2
        endCallButton.layer.cornerRadius = switchCameraButton.frame.height / 2
        localView.layer.cornerRadius = 15
        localView.layer.borderWidth = 2
        localView.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        localView.addGestureRecognizer(tabgesTure)
    }
    
    private func handleIconImage(name: String) -> UIImage? {
        let largeConfig = UIImage.SymbolConfiguration(scale: .large)
        let largeBoldDoc = UIImage(systemName: name, withConfiguration: largeConfig)
        return largeBoldDoc
    }
    
    private func handleSwitchCamera() {
        if localStream == nil { return }
        var pos = localStream?.getCameraPosition()
        if pos == SKWCameraPositionEnum.CAMERA_POSITION_BACK {
            pos = SKWCameraPositionEnum.CAMERA_POSITION_FRONT
        } else if pos == SKWCameraPositionEnum.CAMERA_POSITION_FRONT {
            pos = SKWCameraPositionEnum.CAMERA_POSITION_BACK
        } else {
            return
        }
    }
    
    // MARK: - IBActions
    @IBAction private func switchCamButtonTouchUpInside(_ sender: UIButton) {
        // switch camera
        switchCameraButton.tintColor = .black
        if !isSwitchCamera {
            isSwitchCamera = true
            switchCameraButton.setImage(handleIconImage(name: "arrow.triangle.2.circlepath.camera.fill"), for: .normal)
            handleSwitchCamera()
        } else {
            isSwitchCamera = false
            switchCameraButton.setImage(handleIconImage(name: "arrow.triangle.2.circlepath.camera"), for: .normal)
            handleSwitchCamera()
        }
    }
    
    @IBAction private func voiceButtonTouchUpInside(_ sender: UIButton) {
        // enable voice
        voiceButton.tintColor = .black
        if !isChangeVoice {
            isChangeVoice = true
            localStream?.setEnableAudioTrack(0, enable: false)
            voiceButton.setImage(self.handleIconImage(name: "mic.slash.fill"), for: .normal)
        } else {
            isChangeVoice = false
            localStream?.setEnableAudioTrack(0, enable: true)
            voiceButton.setImage(self.handleIconImage(name: "mic.fill"), for: .normal)
        }
    }
    
    @IBAction private func camButtonTouchInside(_ sender: UIButton) {
        // open camera
        videoButton.tintColor = .black
        if !isChangVideoCall {
            isChangVideoCall = true
            videoButton.setImage(handleIconImage(name: "video.slash.fill"), for: .normal)
            localStream?.removeVideoRenderer(localView, track: 0)
        } else {
            isChangVideoCall = false
            videoButton.setImage(handleIconImage(name: "video.fill"), for: .normal)
            localStream?.addVideoRenderer(localView, track: 0)
        }
    }
    
    @IBAction private func endCallButtonTouchUpInside(_ sender: UIButton) {
        // end call
        dataConnection?.close()
        mediaConnection?.close()
        callCenter.EndCall()
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Objc
    @objc func tabLocalView() {
        // tab to zoom and scale
    }
}

// Setsp Skyway
extension CallViewController {
    
    func setup() {
        let option: SKWPeerOption = SKWPeerOption.init()
        option.key = AppDelegate.shared.skywayAPIKey
        option.domain = AppDelegate.shared.skywayDomain
        peer = SKWPeer(options: option)
        
        if let _peer = peer {
            self.setupPeerCallBacks(peer: _peer)
            self.setupStream(peer: _peer)
        } else {
            let alert = UIAlertController(title: "エラー", message: "PeerのOpenに失敗しました", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func setupStream(peer: SKWPeer) {
        SKWNavigator.initialize(peer)
        let constraints: SKWMediaConstraints = SKWMediaConstraints()
        self.localStream = SKWNavigator.getUserMedia(constraints)
        self.localStream?.addVideoRenderer(self.localView, track: 0)
    }
    
    func call(targetPeerId: String) {
        let option = SKWCallOption()
        if let mediaConnection = self.peer?.call(withId: targetPeerId, stream: self.localStream, options: option) {
            self.mediaConnection = mediaConnection
            self.setupMediaConnectionCallbacks(mediaConnection: mediaConnection)
        } else {
            print("failed to call :\(targetPeerId)")
        }
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
    
    func showPeersDialog(_ peer: SKWPeer, handler: @escaping (String) -> Void) {
        peer.listAllPeers() { peers in
            if let peerIds = peers as? [String] {
                print(peerIds)
                if peerIds.count <= 1 {
                    let alert = UIAlertController(title: "接続中のPeerId", message: "接続先がありません", preferredStyle: .alert)
                    let noAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
                    alert.addAction(noAction)
                    self.present(alert, animated: true, completion: nil)

                }
                else {
                    let alert = UIAlertController(title: "接続中のPeerId", message: "接続先を選択してください", preferredStyle: .alert)
                    for peerId in peerIds{
                        if peerId != peer.identity {
                            let peerIdAction = UIAlertAction(title: peerId, style: .default, handler: { (alert) in
                                handler(peerId)
                            })
                            alert.addAction(peerIdAction)
                        }
                    }
                    let noAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
                    alert.addAction(noAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

// MARK: - CXProviderDelegate
extension CallViewController: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {}
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        callCenter.ConfigureAudioSession()
        callCenter.Connecting()
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        callCenter.ConfigureAudioSession()
        if let peer = self.dataConnection?.peer {
            self.call(targetPeerId: peer)
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        self.dataConnection?.close()
        self.mediaConnection?.close()
        action.fulfill()
    }
}
extension CallViewController {
    
    func setupPeerCallBacks(peer:SKWPeer) {
        peer.on(SKWPeerEventEnum.PEER_EVENT_ERROR) { obj in
            if let error = obj as? SKWPeerError {
                print("\(error)")
            }
        }
        
        peer.on(SKWPeerEventEnum.PEER_EVENT_OPEN) { obj in
            if let peerId = obj as? String{
                DispatchQueue.main.async {
                    //
                }
                print("your peerId: \(peerId)")
            }
        }

        peer.on(SKWPeerEventEnum.PEER_EVENT_CALL) { obj in
            if let connection = obj as? SKWMediaConnection {
                self.setupMediaConnectionCallbacks(mediaConnection: connection)
                self.mediaConnection = connection
                connection.answer(self.localStream)
            }
        }
        
        peer.on(SKWPeerEventEnum.PEER_EVENT_CONNECTION) { obj in
            if let connection = obj as? SKWDataConnection {
                if self.dataConnection == nil {
                    self.callCenter.IncomingCall(true)
                }
                self.dataConnection = connection
                self.setupDataConnectionCallbacks(dataConnection: connection)
            }
        }
    }
    
    func setupMediaConnectionCallbacks(mediaConnection:SKWMediaConnection){
        mediaConnection.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_STREAM) { obj in
            if let msStream = obj as? SKWMediaStream {
                self.remoteStream = msStream
                DispatchQueue.main.async {
                    self.remoteStream?.addVideoRenderer(self.remoteView, track: 0)
                }
                self.callCenter.Connected()
            }
        }

        mediaConnection.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_CLOSE) { obj in
            if let _ = obj as? SKWMediaConnection {
                DispatchQueue.main.async {
                    self.remoteStream?.removeVideoRenderer(self.remoteView, track: 0)
                    self.remoteStream = nil
                    self.dataConnection = nil
                    self.mediaConnection = nil
                }
                self.callCenter.EndCall()
            }
        }
    }
    
    func setupDataConnectionCallbacks(dataConnection:SKWDataConnection) {
        dataConnection.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_OPEN) { obj in
            //
        }

        dataConnection.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_CLOSE) { obj in
            print("close data connection")
            self.dataConnection = nil
            self.callCenter.EndCall()
        }
    }
}
// MARK: - Permision
extension CallViewController {
    func checkPermissionAudio() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break
        case .denied:
            let alert = UIAlertController(title: "マイクの許可", message: "アプリの設定画面からマイクの使用を許可してください", preferredStyle: .alert)
            let settings = UIAlertAction(title: "設定を開く", style: .default) { result in
                UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
            }
            alert.addAction(settings)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true, completion: nil)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { result in
                print("getAudioPermission: \(result)")
            }
        case .restricted:
            let alert = UIAlertController(title:nil, message: "マイクの使用が制限されています（通話することができません）", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        @unknown default:
            break
        }
    }
}
