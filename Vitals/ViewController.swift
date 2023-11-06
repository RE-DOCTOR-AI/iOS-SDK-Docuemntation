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

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var resultView: UITextView!
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
    private let frameConsumer = DefaultFrameConsumerIOS()
    
    private lazy var vitalSignProcessor: VitalSignProcessorIOS = {
        return VitalSignProcessorIOS()
    }()
    
    private lazy var glucoseLevelProcessor: GlucoseLevelProcessorIOS = {
        return GlucoseLevelProcessorIOS(filePath: self.getModelPaths())
    }()
    
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
        
        let endTime = Date().timeIntervalSince1970
        let diff = endTime - startTime
        let measurementCount = VitalsScannerSDK.shared.MEASUREMENT_COUNT
        
        //add 5 seconds delay to allow camera to focus
        if diff > 5 {
            do {
                var frameConsumerStatus: String
                
                let averageFrameRGB: FrameAverageRgbIOS = FrameAverageRgbIOS(
                    averageRed: Double(redAverage),
                    averageGreen: Double(greenAverage),
                    averageBlue: Double(blueAverage)
                )
                let frameTimestamp = self.getCurrentTimestampInMillis()
                frameConsumerStatus = frameConsumer.ingestRGB(averageRGB: averageFrameRGB, timestamp: frameTimestamp).name

                //start validating each frame
                if (frameConsumer.getVitalsFramesData().counter % 50 == 0) {
                    let redArray = redVector.map({KotlinFloat.init(float: $0)})
                    let frameValidated = ImageValidationUtilsKt.validateFrameIos(redArray: redArray)
                    if (frameValidated == false) {
                        frameConsumerStatus = "MEASUREMENT_FAILED"
                        frameConsumer.resetFramesData()
                        startTime = Date().timeIntervalSince1970
                    }
                }
                
                //Here we update the progress bar
                DispatchQueue.global().async {
                    DispatchQueue.main.async { () -> Void in
                        let count = self.frameConsumer.getVitalsFramesData().counter
                        self.progress.setProgress(Float(count)/Float(measurementCount), animated:false)
                    }
                }
                
                if (frameConsumerStatus == "IN_PROGRESS") {
                    //Here we update the process status text
                    DispatchQueue.global().async {
                        DispatchQueue.main.async { () -> Void in
                            self.resultView.text = "Process status: measurement in progress..."
                        }
                    }
                } else if (frameConsumerStatus == "START_CALCULATING") {
                    DispatchQueue.global().async {
                        DispatchQueue.main.async { () -> Void in
                            self.resultView.text = "Process status: Calculating results..."
                            
                            //hiding everything on the view
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
    }
    
    func calculateVitals() -> Void {
        var vitalSignProcessorStatus = vitalSignProcessor.process(framesData: frameConsumer.getVitalsFramesData()).name
        
        let ResultedO2 : String = "O2="+self.vitalSignProcessor.getSPo2Value()+"\n"
        let ResultedBeats : String = "Beats="+String((Int(self.vitalSignProcessor.getBeatsValue()) ?? 0))+"\n"
        let ResultedBreath : String = "Breath="+self.vitalSignProcessor.getBreathValue()+"\n"
        let ResultedDP : String = "DP="+self.vitalSignProcessor.getDPValue()+"\n"
        let ResultedSP : String = "SP="+self.vitalSignProcessor.getSPValue()+"\n"
        let ResultedRiskLevel: String = "RiskLevel="+self.vitalSignProcessor.getRiskLevelValue()+"\n"
        let ResultedPulsePressure: String = "PulsePressure="+self.vitalSignProcessor.getPulsePressureValue()+"\n"
        let ResultedStress: String = "Stress="+self.vitalSignProcessor.getStressValue()+"\n"
        let ResultedReflectionIndex: String = "ReflectionIndex="+self.vitalSignProcessor.getReflectionIndexValue()+"\n"
        let ResultedLasi: String = "Lasi="+self.vitalSignProcessor.getLasiValue()+"\n"
        let ResultedHrv: String = "Hrv="+self.vitalSignProcessor.getHrvValue()+"\n"
        
        print(vitalSignProcessorStatus)
        print(ResultedO2)
        print(ResultedBeats)
        print(ResultedBreath)
        print(ResultedDP)
        print(ResultedSP)
        print(ResultedRiskLevel)
        print(ResultedPulsePressure)
        print(ResultedStress)
        print(ResultedReflectionIndex)
        print(ResultedLasi)
        print(ResultedHrv)
        
        //putting values to Singleton to show them on viewController
        Singleton.sharedInstance.SpO2 = self.vitalSignProcessor.getSPo2Value()
        Singleton.sharedInstance.Respiration = self.vitalSignProcessor.getBreathValue()
        Singleton.sharedInstance.HeartRate = (Int(self.vitalSignProcessor.getBeatsValue()) ?? 0) == 0 ? "0" : String((Int(self.vitalSignProcessor.getBeatsValue()) ?? 0))
        Singleton.sharedInstance.BloodPressure = self.vitalSignProcessor.getSPValue()+"/"+self.vitalSignProcessor.getDPValue()
        Singleton.sharedInstance.SBP = self.vitalSignProcessor.getSPValue()
        Singleton.sharedInstance.DBP = self.vitalSignProcessor.getDPValue()
        Singleton.sharedInstance.riskLevel = self.vitalSignProcessor.getRiskLevelValue()
        Singleton.sharedInstance.lasi = self.vitalSignProcessor.getLasiValue()
        Singleton.sharedInstance.reflectionIndex = self.vitalSignProcessor.getReflectionIndexValue()
        Singleton.sharedInstance.pulsePressure = self.vitalSignProcessor.getPulsePressureValue()
        Singleton.sharedInstance.stress = self.vitalSignProcessor.getStressValue()
        Singleton.sharedInstance.hrv = self.vitalSignProcessor.getHrvValue()
    }
    
    func calculateGlucose() -> Void {
        DispatchQueue.main.sync {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "Results")
            self.present(nextViewController, animated:true, completion:nil)
            let text = "processing"
            var dotCount = 0
            var isIncreasing = true
            var timer: Timer?
            (nextViewController  as! ViewControllerResults).Glucose.textAlignment = NSTextAlignment.left

            DispatchQueue.main.async {
                timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) {_ in
                    if isIncreasing {
                        dotCount += 1
                        if dotCount == 4 {
                            isIncreasing = false
                        }
                    } else {
                        dotCount -= 1
                        if dotCount == 0 {
                            isIncreasing = true
                        }
                    }
                    let dots = String(repeating: ".", count: dotCount)
                    let animatedText = "\(text)\(dots)"
                    (nextViewController  as! ViewControllerResults).Glucose.text=animatedText
                }
            }
            timer?.fire()
            (nextViewController  as! ViewControllerResults).Glucose.textColor=UIColor.systemBlue
            
            DispatchQueue.global().async {
                //start processing
                var glucoseProcessingStatus = self.glucoseLevelProcessor.process(framesData: self.frameConsumer.getGlucoseFrameData()).name
                let glucoseMin = self.glucoseLevelProcessor.getGlucoseMinValue()
                let glucoseMax = self.glucoseLevelProcessor.getGlucoseMaxValue()
                
                Singleton.sharedInstance.glucose = "[\(glucoseMin) - \(glucoseMax)]"
                Singleton.sharedInstance.glucoseMean = Int32(((glucoseMin)+(glucoseMax))/2)
                DispatchQueue.main.async {
                    (nextViewController  as! ViewControllerResults).Glucose.textColor=UIColor.label
                    //showing result
                    (nextViewController  as! ViewControllerResults).Glucose.text=Singleton.sharedInstance.glucose
                    (nextViewController  as! ViewControllerResults).StartAgain.isEnabled=true
                    (nextViewController  as! ViewControllerResults).Glucose.textAlignment=NSTextAlignment.right
                    timer?.invalidate()
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
    
    private func getModelPaths() -> KotlinArray<NSString> {
        let filePath1 = Bundle.main.path(forResource: "models/model_fold0", ofType: "ptl")! as NSString
        let filePath2 = Bundle.main.path(forResource: "models/model_fold1", ofType: "ptl")! as NSString
        let filePath3 = Bundle.main.path(forResource: "models/model_fold2", ofType: "ptl")! as NSString
        let filePath4 = Bundle.main.path(forResource: "models/model_fold3", ofType: "ptl")! as NSString
        let filePath5 = Bundle.main.path(forResource: "models/model_fold4", ofType: "ptl")! as NSString
        let filePaths: [NSString] = [filePath1, filePath2, filePath3, filePath4, filePath5]
        let paths = KotlinArray<NSString>(size: 5, init: { (i: KotlinInt) -> NSString in return filePaths[i.intValue] })
        return paths
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

class ViewControllerResults: UIViewController{
    @IBOutlet var SpO2: UILabel!
    @IBOutlet var Respiration: UILabel!
    @IBOutlet var HeartRate: UILabel!
    @IBOutlet var BloodPressure: UILabel!
    @IBOutlet var riskLevel: UILabel!
    @IBOutlet var pulsePressure: UILabel!
    @IBOutlet var stress: UILabel!
    @IBOutlet var reflectionIndex: UILabel!
    @IBOutlet var hrv: UILabel!
    @IBOutlet var lasi: UILabel!
    @IBOutlet var Glucose: UILabel!
    @IBOutlet var StartAgain: UIButton!
    
    var existingPatientResponse: [User_] = []
    var existingPatient: User_?
    var newPatientResponse: CreatedUser?
    var newPatient: CreatedUser?
    let keychain = KeychainSwift()
    
    override func viewDidLoad()
    {
        SpO2.text = Singleton.sharedInstance.SpO2
        Respiration.text = Singleton.sharedInstance.Respiration == "0" ? "not enough data" : Singleton.sharedInstance.Respiration
        HeartRate.text = Singleton.sharedInstance.HeartRate == "0" ? "not enough data" : Singleton.sharedInstance.HeartRate
        BloodPressure.text = Singleton.sharedInstance.BloodPressure
        riskLevel.text = Singleton.sharedInstance.riskLevel
        pulsePressure.text = Singleton.sharedInstance.pulsePressure
        hrv.text = Singleton.sharedInstance.hrv
        lasi.text = Singleton.sharedInstance.lasi
        stress.text = Singleton.sharedInstance.stress
        reflectionIndex.text = Singleton.sharedInstance.reflectionIndex
        StartAgain.isEnabled=false
        super.viewDidLoad()
    }
}


class ViewControllerStart: UIViewController{
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

//so tht we can share the data between app views (screens) and view controllers
class Singleton {
    var patientHeight : Double = 0.0
    var patientWeight : Double = 0.0
    var patientAge : String = "0"
    var patientGender : Int32 = 0
    
    var SpO2: String = "0"
    var glucose: String = "0"
    var glucoseMean: Int32 = 0
    var Respiration: String = "0"
    var HeartRate: String = "0"
    var BloodPressure: String = "0"
    var SBP : String = "0"
    var DBP : String = "0"
    var riskLevel : String = "LOW"
    var pulsePressure: String = "0"
    var stress: String = "0"
    var reflectionIndex: String = "0"
    var hrv: String = "0"
    var lasi: String = "0"
    
    static let sharedInstance = Singleton()
    private init(){
        
    }
}
