//
//  CameraController.swift
//  DemoCallKit
//
//  Created by T.Minh on 7/7/21.
//

import UIKit
import Foundation
import AVFoundation

class CameraController: NSObject {
    // MARK: - Enum
    enum Error: Swift.Error {
        case inputsAreInvalid
        case captureSessionIsMissing
        case noCamerasAvailable
        case invalidOperation
        case crop
        case noMetaRect
        case unknown
    }
    
    enum plashMode {
        case on, off, auto
    }
    
    enum CameraType {
        case back, front
    }
    
    // MARK: - Peroperties
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureDevice: AVCaptureDevice!
    private var photoOutput: AVCapturePhotoOutput!
    private var photoCaptureCompletion: ((UIImage?, Error?) -> Void)?
    private var rectToCrop: CGRect?
    private var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    
    func captureSetup(in cameraView: UIView, completionHandler: @escaping (Error?) -> Void) {
        captureSession = AVCaptureSession()
        do {
            try configureCaptureDevices()
            try configureDeviceInputs()
            try configurePhotoOutput()
            try displayPreview(on: cameraView)
        } catch {
            completionHandler(error as? CameraController.Error)
        }
    }
    
    private func configureCaptureDevices() throws {
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        guard let firstAvailableDevice = availableDevices.first else { throw Error.noCamerasAvailable }
        captureDevice = firstAvailableDevice
        let settings = AVCapturePhotoSettings()
        settings.flashMode = AVCaptureDevice.FlashMode.off
    }
    
    private func configureDeviceInputs() throws {
        guard let captureSession = self.captureSession else { throw Error.captureSessionIsMissing }
        
        let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        } else {
            throw Error.inputsAreInvalid
        }
    }
    
    private func configurePhotoOutput() throws {
        guard let captureSession = self.captureSession else { throw Error.captureSessionIsMissing }
        photoOutput = AVCapturePhotoOutput()
        photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
        if let photoOutput = self.photoOutput {
            captureSession.addOutput(photoOutput)
        } else {
            throw Error.invalidOperation
        }
        captureSession.startRunning()
    }
    
    private func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw Error.captureSessionIsMissing }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(previewLayer)
        previewLayer.connection?.videoOrientation = .portrait
    }
    
    // captureImage after to take photo
    func captureImage(cropWith rect: CGRect? = nil, completion: @escaping (UIImage?, Error?) -> Void) {
        guard let captureSession = captureSession, captureSession.isRunning else {
            completion(nil, Error.captureSessionIsMissing)
            return }
        let settings = AVCapturePhotoSettings()
        settings.flashMode = AVCaptureDevice.FlashMode.off
        
        photoOutput?.capturePhoto(with: settings, delegate: self)
        rectToCrop = rect
        photoCaptureCompletion = completion
    }
    
    // MARK: -
    func startRunning() {
        if captureSession?.isRunning != true {
            captureSession.startRunning()
        }
    }
    
    func stopRunning() {
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    func getSettings(flashMode: AVCaptureDevice.FlashMode) -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        if captureDevice.hasFlash {
            settings.flashMode = flashMode
        }
        return settings
    }
    
    private func crop(image: UIImage, withRect rect: CGRect) throws -> UIImage {
        let originalSize: CGSize
        guard let metaRect = previewLayer?.metadataOutputRectConverted(fromLayerRect: rect) else {
            throw Error.noMetaRect
        }
        if image.imageOrientation == UIImage.Orientation.left
            || image.imageOrientation == UIImage.Orientation.right {
            originalSize = CGSize(width: image.size.height,
                                  height: image.size.width)
        } else {
            originalSize = image.size
        }
        
        let x = metaRect.origin.x * originalSize.width
        let y = metaRect.origin.y * originalSize.height
        let cropRect: CGRect = CGRect( x: x,
                                       y: y,
                                       width: metaRect.size.width * originalSize.width,
                                       height: metaRect.size.height * originalSize.height).integral
        guard let cropedCGImage = image.cgImage?.cropping(to: cropRect) else {
            throw Error.crop
        }
        
        let image = UIImage(cgImage: cropedCGImage,
                            scale: 1,
                            orientation: image.imageOrientation)
        return image
    }
}
extension CameraController: AVCapturePhotoCaptureDelegate {
  
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                        resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Swift.Error?) {
        if let error = error {
            photoCaptureCompletionBlock?(nil, error as? CameraController.Error)
        } else if let buffer = photoSampleBuffer,
            let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: nil),
            let image = UIImage(data: data) {
            if let rect = rectToCrop {
                do {
                    let image = try crop(image: image, withRect: rect)
                    photoCaptureCompletionBlock?(image, nil)
                } catch {
                    photoCaptureCompletionBlock?(nil, error as? CameraController.Error)
                }
            } else {
                photoCaptureCompletionBlock?(image, nil)
            }
        } else {
            photoCaptureCompletionBlock?(nil, Error.unknown)
        }
    }
}

