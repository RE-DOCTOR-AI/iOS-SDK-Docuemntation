//
//  ViewController.swift
//  ProcessingCameraFeed
//

import UIKit
import WebKit
import AVFoundation
import VideoToolbox
import shared
import Accelerate
import CoreMedia.CMFormatDescription


//Extension to hide keyboard if user clicked outside of textfield
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet var textView: UITextView!
    @IBOutlet var resultView: UITextView!
    @IBOutlet var validationView: UITextView!
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var VideoView: UIView!
    @IBOutlet var OverlayView: UIView!
    let keychain = KeychainSwift()
    var startTime = Date().timeIntervalSince1970
    
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        return preview
    }()
    
    
    private let videoOutput = AVCaptureVideoDataOutput()
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addCameraInput()
        self.addPreviewLayer()
        self.addVideoOutput()
        self.toggleTorch(on: true)
        
        self.captureSession.startRunning()
        self.captureSession.sessionPreset = AVCaptureSession.Preset.low;
        let captureDevice = AVCaptureDevice.default(for: .video)!
        
        do {
            try captureDevice.lockForConfiguration()
            
            captureDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1,timescale: 30)
            captureDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1,timescale: 30)
            
            captureDevice.unlockForConfiguration()
            print(captureDevice.activeFormat)
            print(captureDevice.activeVideoMaxFrameDuration)
            print(captureDevice.activeVideoMinFrameDuration)
        }
        catch {
            // Couldn't create audio player object, log the error
            print("Error=\(error)")
        }
        
        self.toggleTorch(on: true)
        
        //prevent display from going to sleep
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.VideoView.frame
        self.previewLayer.videoGravity = .resizeAspect
    }
    
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let width = CVPixelBufferGetWidth(imageBuffer!)
        let height = CVPixelBufferGetHeight(imageBuffer!)
        let src_buff = CVPixelBufferGetBaseAddress(imageBuffer!)
        let dataBuffer = src_buff!.assumingMemoryBound(to: UInt8.self) // *
        
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        let numberOfPixels = height * width
        var greenVector:[Float] = Array(repeating: 0.0, count: numberOfPixels)
        var blueVector:[Float] = Array(repeating: 0.0, count: numberOfPixels)
        var redVector:[Float] = Array(repeating: 0.0, count: numberOfPixels)
        
        //calculate rgb values for one frame
        vDSP_vfltu8(dataBuffer, 4, &blueVector, 1, vDSP_Length(numberOfPixels))
        vDSP_vfltu8(dataBuffer+1, 4, &greenVector, 1, vDSP_Length(numberOfPixels))
        vDSP_vfltu8(dataBuffer+2, 4, &redVector, 1, vDSP_Length(numberOfPixels))
        var redAverage:Float = 0.0
        var blueAverage:Float = 0.0
        var greenAverage:Float = 0.0
        
        //calculate avg rgb value
        vDSP_meamgv(&redVector, 1, &redAverage, vDSP_Length(numberOfPixels))
        vDSP_meamgv(&greenVector, 1, &greenAverage, vDSP_Length(numberOfPixels))
        vDSP_meamgv(&blueVector, 1, &blueAverage, vDSP_Length(numberOfPixels))
        
        let measurementCount = VitalsScannerSDK.shared.MEASUREMENT_COUNT
        
        do {
            var frameConsumerStatus: String
            
            let averageFrameRGB: FrameAverageRgbIOS = FrameAverageRgbIOS(
                averageRed: Double(redAverage),
                averageGreen: Double(greenAverage),
                averageBlue: Double(blueAverage)
            )
            let frameTimestamp = self.getCurrentTimestampInMillis()
            frameConsumerStatus = Singleton.sharedInstance.frameConsumer.ingestRGB(averageRGB: averageFrameRGB, timestamp: frameTimestamp).name
            
            if (frameConsumerStatus == "SKIP") {
                return // Do nothing, frame will not be included in the data set
            }
            
            //start validating each frame
            if (Singleton.sharedInstance.frameConsumer.getVitalsFramesData().counter % 50 == 0) {
                let redArray = redVector.map({KotlinFloat.init(float: $0)})
                let frameValidated = ImageValidationUtilsKt.validateFrameIos(redArray: redArray)

                if (frameValidated.error != nil) {
                    frameConsumerStatus = "VALIDATION_FAILED"
                    
                    DispatchQueue.main.sync {
                        //Here we update the process status text
                        self.validationView.text = "Validation failed: " + frameValidated.error!
                    }
                    Singleton.sharedInstance.frameConsumer.resetFramesData()
                }
            }
            
            //Here we update the progress bar
            DispatchQueue.global().async {
                DispatchQueue.main.async { () -> Void in
                    let count = Singleton.sharedInstance.frameConsumer.getVitalsFramesData().counter
                    self.progress.setProgress(Float(count)/Float(measurementCount), animated: false)
                }
            }
            
            if (frameConsumerStatus == "IN_PROGRESS") {
                // TODO: validate intermediate data here
                // Here we update the process status text
                DispatchQueue.global().async {
                    DispatchQueue.main.async { () -> Void in
                        self.resultView.text = "Process status: measurement in progress..."
                        self.validationView.text = ""
                    }
                }
            } else if (frameConsumerStatus == "START_CALCULATING") {
                DispatchQueue.global().async {
                    DispatchQueue.main.async { () -> Void in
                        self.resultView.text = "Process status: Calculating results..."
                        self.validationView.text = ""
                        
                        //creating alert dialog and hiding everything on the view
                        self.VideoView.removeFromSuperview()
                        self.VideoView.frame.size.width = 0
                        self.VideoView.frame.size.height = 0
                        self.resultView.isHidden = true
                        self.progress.isHidden = true
                        self.captureSession.stopRunning()
                    }
                }
                
                self.calculateVitals()
                self.calculateGlucose()
            } else if (frameConsumerStatus == "MEASUREMENT_FAILED") {
                DispatchQueue.main.sync {
                    //Here we update the process status text
                    self.resultView.text = "Process status: Let's try one more time!"
                }
            }
        }
    }
    
    func calculateVitals() -> Void {
        var vitalSignProcessorStatus = Singleton.sharedInstance.vitalSignProcessor.process(framesData: Singleton.sharedInstance.frameConsumer.getVitalsFramesData()).name
                
        // Putting values to Singleton to make them accessible from different parts of the app
        Singleton.sharedInstance.SpO2 = Singleton.sharedInstance.vitalSignProcessor.getSPo2Value()
        Singleton.sharedInstance.Respiration = Singleton.sharedInstance.vitalSignProcessor.getBreathValue()
        Singleton.sharedInstance.HeartRate = (Int(Singleton.sharedInstance.vitalSignProcessor.getBeatsValue()) ?? 0) == 0 ? "0" : String((Int(Singleton.sharedInstance.vitalSignProcessor.getBeatsValue()) ?? 0))
        Singleton.sharedInstance.BloodPressure = "\(Singleton.sharedInstance.vitalSignProcessor.getSPValue()) / \(Singleton.sharedInstance.vitalSignProcessor.getDPValue())"
        Singleton.sharedInstance.SBP = Singleton.sharedInstance.vitalSignProcessor.getSPValue()
        Singleton.sharedInstance.DBP = Singleton.sharedInstance.vitalSignProcessor.getDPValue()
        Singleton.sharedInstance.lasi = Singleton.sharedInstance.vitalSignProcessor.getLasiValue()
        Singleton.sharedInstance.reflectionIndex = Singleton.sharedInstance.vitalSignProcessor.getReflectionIndexValue()
        Singleton.sharedInstance.pulsePressure = Singleton.sharedInstance.vitalSignProcessor.getPulsePressureValue()
        Singleton.sharedInstance.stress = Singleton.sharedInstance.vitalSignProcessor.getStressValue()
        Singleton.sharedInstance.hrv = Singleton.sharedInstance.vitalSignProcessor.getHrvValue()
    }
    
    func calculateGlucose() -> Void {
        DispatchQueue.main.sync {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "Results")
            self.present(nextViewController, animated: true, completion: nil)
            (nextViewController  as! ViewControllerResults).animateProgress()
            
            DispatchQueue.global().async {
                // Start processing
                var glucoseProcessingStatus = Singleton.sharedInstance.glucoseProcessor.process(framesData: Singleton.sharedInstance.frameConsumer.getGlucoseFrameData()).name
                let glucoseMin = Singleton.sharedInstance.glucoseProcessor.getGlucoseMinValue()
                let glucoseMax = Singleton.sharedInstance.glucoseProcessor.getGlucoseMaxValue()
                let glucoseMean = (glucoseMin + glucoseMax) / 2
                let risk = Singleton.sharedInstance.vitalSignProcessor.getRiskLevelValue()
                var riskLevel = RiskLevel.unknown

                if (risk != nil) {
                    let riskLevelValue = VitalsRiskLevelIOSKt.getVitalsWithGlucose(vitalsRiskLevel: risk!, glucose: Double(glucoseMean))
                    riskLevel = VitalsRiskLevelKt.getRiskLevel(riskGrades: riskLevelValue)
                }
                
                let glucoseResultText = "[\(glucoseMin) - \(glucoseMax)]"
                Singleton.sharedInstance.glucose = glucoseResultText
                Singleton.sharedInstance.glucoseMean = glucoseMean
                Singleton.sharedInstance.riskLevel = riskLevel.name
                
                DispatchQueue.main.async {
                    (nextViewController  as! ViewControllerResults).Glucose.textColor = UIColor.label
                    // Showing result
                    (nextViewController  as! ViewControllerResults).Glucose.text = glucoseResultText
                    (nextViewController  as! ViewControllerResults).riskLevel.text = riskLevel.name
                    (nextViewController  as! ViewControllerResults).StartAgain.isEnabled = true
                    (nextViewController  as! ViewControllerResults).CollectData.isEnabled = true
                    (nextViewController  as! ViewControllerResults).stopAnimateProgress()
                }
            }
        }
    }
    
    func getCurrentTimestampInMillis() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
        
    @objc func savedImage(_ im:UIImage, error:Error?, context:UnsafeMutableRawPointer?) {
        if let err = error {
            print(err)
            return
        }
        print("success")
    }
    
    
    private func addCameraInput() {
        let device = AVCaptureDevice.default(for: .video)!
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func addPreviewLayer() {
        self.view.layer.addSublayer(self.previewLayer)
    }
    
    private func addVideoOutput() {
        self.videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.image.handling.queue"))
        self.captureSession.addOutput(self.videoOutput)
    }

    
    func convert(cmage: CIImage) -> UIImage {
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(cmage, from: cmage.extent)!
        let image = UIImage(cgImage: cgImage)
        return image
    }
    
    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    
}
//this is to check if resizing to 177x144 px will help. Usage  UIImage().resize(200, 300)
extension UIImage {
    func resize(_ width: CGFloat, _ height:CGFloat) -> UIImage? {
        let widthRatio  = width / size.width
        let heightRatio = height / size.height
        let ratio = widthRatio > heightRatio ? heightRatio : widthRatio
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}


class ViewControllerStart: UIViewController {
    @IBOutlet var NextButton: UIButton!
    @IBOutlet var Version: UILabel!
    let keychain = KeychainSwift()
    var FName : String = ""
    var LName : String = ""
    var Height: String = ""
    var Weight: String = ""
    var Age: String = ""
    var Gender: String = ""
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.autoresizesSubviews = true
        setVersionNumber()
    }
    
    func setVersionNumber(){
        let version: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"]! as! String
        let boundleVersion: String = Bundle.main.infoDictionary!["CFBundleVersion"]! as! String
        Version.text = version + "(" + boundleVersion + ")"
    }
    
}
