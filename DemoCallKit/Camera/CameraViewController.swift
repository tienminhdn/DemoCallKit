//
//  CameraViewController.swift
//  DemoCallKit
//
//  Created by T.Minh on 7/7/21.
//

import UIKit
import AVFoundation

final class CameraViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet private weak var cancleButton: UIButton!
    @IBOutlet private weak var switchButton: UIButton!
    @IBOutlet private weak var switchView: UIView!
    @IBOutlet private weak var takePhotoButton: UIButton!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var splashButton: UIButton!
    @IBOutlet private weak var cameraView: UIView!
    @IBOutlet private weak var scaleView: UIView!
    @IBOutlet private weak var oneScaleButton: UIButton!
    @IBOutlet private weak var twoScaleButton: UIButton!
    @IBOutlet private weak var zeroPointFiveButtonscale: UIButton!
    
    // MARK: - Peroperties
    var cameraController = CameraController()
    private var flashMode = AVCapturePhotoSettings().flashMode
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        configUI()
        setUpCamera()
        requestPermission()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraController.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraController.stopRunning()
    }
    
    // MARK: - Private func
    private func configUI() {
        scaleView.layer.cornerRadius = scaleView.frame.height / 2
        zeroPointFiveButtonscale.layer.cornerRadius = zeroPointFiveButtonscale.frame.height / 2
        oneScaleButton.layer.cornerRadius = oneScaleButton.frame.height / 2
        twoScaleButton.layer.cornerRadius = twoScaleButton.frame.height / 2
        takePhotoButton.layer.cornerRadius = takePhotoButton.frame.height / 2
        switchView.layer.cornerRadius = switchView.frame.height / 2
        splashButton.tintColor = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)
    }
    
    private func handleIconImage(name: String) -> UIImage? {
        let largeConfig = UIImage.SymbolConfiguration(scale: .large)
        let largeBoldDoc = UIImage(systemName: name, withConfiguration: largeConfig)
        return largeBoldDoc
    }
    
    private func setUpCamera() {
        cameraController.captureSetup(in: cameraView) { (error) in
            if let error = error {
                print(error)
            }
        }
        
    }
    
    private func requestPermission() {
        let permission = AVCaptureDevice.authorizationStatus(for: .video)
        switch permission {
        case .authorized:
            setUpCamera()
        case .notDetermined: // cần sự cho phép
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] granted in
                DispatchQueue.main.async { [weak self] in
                    guard let this = self else { return }
                    if !granted {
                        this.navigationController?.popViewController(animated: true)
                    } else {
                        this.setUpCamera()
                    }
                }
            })
        case .denied, .restricted: // người dùng từ chối
            // show alert -> pop root or send to URL setup
            print("not allow")
        default:
            break
        }
    }
    
    // MARK: - IBActions
    @IBAction private func splashButtonTouchUpInside(_ sender: UIButton) {
        switch flashMode {
        case .on:
            splashButton.setImage(handleIconImage(name: "bolt.slash"), for: .normal)
            flashMode = AVCaptureDevice.FlashMode.off
        case .off:
            splashButton.setImage(handleIconImage(name: "bolt.badge.a"), for: .normal)
            flashMode = AVCaptureDevice.FlashMode.auto
        case .auto:
            splashButton.setImage(handleIconImage(name: "bolt"), for: .normal)
            flashMode = AVCaptureDevice.FlashMode.on
        default:
            splashButton.setImage(handleIconImage(name: "bolt.slash"), for: .normal)
            flashMode = AVCaptureDevice.FlashMode.off
        }
    }
    
    @IBAction private func scaleOneButtonTouchUpInside(_ sender: UIButton) {
        oneScaleButton.setTitleColor(#colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1), for: .normal)
        twoScaleButton.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: .normal)
        zeroPointFiveButtonscale.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: .normal)
    }
    
    @IBAction private func zeroFiveButtonTouchUpInside(_ sender: UIButton) {
        oneScaleButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        twoScaleButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        zeroPointFiveButtonscale.setTitleColor(#colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1), for: .normal)
    }
    
    @IBAction private func twoButtonTouchUpInside(_ sender: UIButton) {
        oneScaleButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        twoScaleButton.setTitleColor(#colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1), for: .normal)
        zeroPointFiveButtonscale.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
    }
    
    @IBAction private func takePhotoButtonTouchUpInside(_ sender: UIButton) {
        cameraController.captureImage(cropWith: cameraView.frame) { [weak self] (image, error) in
            guard let _ = self, let image = image else {
                print(error ?? "Image capture error")
                return
            }
            print("\(image)")
        }
    }
    
    @IBAction private func switchButtonTouchUpInside(_ sender: UIButton) {
        
    }
    
    @IBAction private func cancelButtonTouchUpInside(_ sender: UIButton) {
        
    }
}
