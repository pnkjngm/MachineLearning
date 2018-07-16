//
//  ViewController.swift
//  MLOne
//
//  Created by iSteer Inc. on 22/10/17.
//  Copyright © 2017 iSteer Inc. All rights reserved.
//

import UIKit
import AVKit
import Vision
import CoreML

class ViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var lblObject: UILabel!
    @IBOutlet weak var lblConfidence: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // plist camera open warning
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "QueueVideo"))
        captureSession.addOutput(dataOutput)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session : captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = cameraView.bounds
        cameraView.layer.addSublayer(previewLayer)
    }
    
}

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer : CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { (requestFinished, Err) in
            if Err != nil {
                print("Error is :", Err as Any)
            }
            guard let results = requestFinished.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            
            print(firstObservation.identifier, firstObservation.confidence )
            DispatchQueue.main.async {
                self.lblObject.text = firstObservation.identifier
                self.lblConfidence.text = String(firstObservation.confidence)

            }
            
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}

