//
//  CallCenter.swift
//  DemoCallKit
//
//  Created by T.Minh on 7/5/21.
//

import UIKit
import Foundation
import AVFoundation
import SkyWay
import CallKit

class CallCenter: NSObject {
    
    private let controller = CXCallController()
    private let provider: CXProvider
    private var uuid = UUID()
    
    init(supportsVideo: Bool) {
        // thiết lập khởi tạo 1 phiên bản CXProvider: báo cáo cuộc gọi đến mới từ các sự kiện
        let providerConfiguration = CXProviderConfiguration.init()
        providerConfiguration.supportsVideo = supportsVideo
        provider = CXProvider(configuration: providerConfiguration)
    }
    
    func setup(_ delegate: CXProviderDelegate) {
        provider.setDelegate(delegate, queue: nil)
    }
    
    // Bắt đầu cuộc gọi đi
    func StartCall(_ hasVideo: Bool = false) {
        uuid = UUID()
        // duy nhất, nhằm xác đinh cuộc gọi
        // CXHandle: xac đinh phương tiện có thể liên lạc được: ex: PeerID
        let handle = CXHandle(type: .generic, value: "花子さん")
        // CXHandle : để xác định người gọi khác trong lịch sử cuộc gọi
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)
        startCallAction.isVideo = hasVideo
        let transaction = CXTransaction(action: startCallAction)
        controller.request(transaction) { error in
            if let error = error {
                print("CXStartCallAction error: \(error.localizedDescription)")
            }
        }
    }
    
    // 
    func IncomingCall(_ hasVideo: Bool = false) {
        uuid = UUID()
        // thông báo có cuộc gọi đến mới
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "太郎さん")
        update.hasVideo = hasVideo
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("reportNewIncomingCall error: \(error.localizedDescription)")
            }
        }
    }
    
    func EndCall() {
        // ghi lại lịch sử cuộc gọi sau khi kết thúc
        let action = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: action)
        controller.request(transaction) { error in
            if let error = error {
                print("CXEndCallAction error: \(error.localizedDescription)")
            }
        }
    }
    
    // báo cáo một cuộc gọi đi đã bắt đầu kết nối
    func Connecting() {
        provider.reportOutgoingCall(with: uuid, startedConnectingAt: nil)
    }
    
    // báo cáo cuộc gọi đã đựơc kết nối
    func Connected() {
        provider.reportOutgoingCall(with: uuid, connectedAt: nil)
    }
    
    func ConfigureAudioSession() {
        // Setup AudioSession
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: .voiceChat, options: [])
    }
}

// thông báo khi có sự thay đổi trong quá trình gọi: video, audio
extension CallCenter {
    func setupNotifications() {
        //
    }
}
