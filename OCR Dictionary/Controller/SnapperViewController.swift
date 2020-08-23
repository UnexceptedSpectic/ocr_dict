//
//  SnapperViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 6/3/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit
import AVFoundation

class SnapperViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var snapButton: UIButton!
    @IBOutlet weak var capturingIndicator: UIActivityIndicatorView!
    var wordFocusBoxLabel: UILabel!
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var capturedImage: UIImage?
    
    // Called only once, when the app loads
    override func viewDidLoad() {
        super.viewDidLoad()

        snapButton.isHidden = false
        capturingIndicator.isHidden = true
        capturingIndicator.style = .medium
        capturingIndicator.color = .black
        wordFocusBoxLabel = SnapperViewController.generateWordFocusBoxLabel(view: self.view)
        cameraView.addSubview(wordFocusBoxLabel)
        
        // Do any additional setup after loading the view.
    }
    
    // Called every time the view loads
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        snapButton.isHidden = false
        capturingIndicator.isHidden = true
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            let input = try AVCaptureDeviceInput(device: backCamera!)
            stillImageOutput = AVCapturePhotoOutput()
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
        
        DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
            self.captureSession.startRunning()
        }
        
        DispatchQueue.main.async {
            self.videoPreviewLayer.frame = self.cameraView.bounds
        }
        
        viewWillDisappear(true)
        
    }
    
    public static func generateWordFocusBoxLabel(view: UIView) -> UILabel {
        
        let label = UILabel()
        label.frame =
            CGRect(x: view.frame.width / 2 - view.frame.width / 3 / 2,
                   y: view.frame.height / 2 - view.frame.height / 12,
                   width: view.frame.width / 3,
                   height: view.frame.height / 12)
        label.layer.borderColor = UIColor.white.cgColor
        label.layer.borderWidth = 2.0
        return label
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.cgImageRepresentation()?.takeUnretainedValue()
            else { return }
        self.capturedImage = UIImage(cgImage: imageData).rotate(radians: .pi/2)
        performSegue(withIdentifier: "SnapperToCropper", sender: self)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    func setupLivePreview() {
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.connection?.videoOrientation = .portrait
        cameraView.layer.addSublayer(videoPreviewLayer)
        cameraView.layer.addSublayer(wordFocusBoxLabel.layer)
    }
    
    @IBAction func snapPhoto(_ sender: UIButton) {
        
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        stillImageOutput.capturePhoto(with: settings, delegate: self)
        videoPreviewLayer.connection?.isEnabled = false
        capturingIndicator.startAnimating()
        snapButton.isHidden = true
        capturingIndicator.isHidden = false
    }
    
  
    @IBAction func cancelSnap(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cropperVC = segue.destination as! ChooserViewController
        cropperVC.capturedImage = self.capturedImage
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    

}

extension UIImage {
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
}
