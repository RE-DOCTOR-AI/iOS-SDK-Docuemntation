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
    @IBOutlet var validationView: UITextView!
    @IBOutlet var patientHeight: UILabel!
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var VideoView: UIView!
    @IBOutlet var OverlayView: UIView!
    
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        //preview.frame = CGRect(x: 0, y: 0, width: VideoView.bounds.width, height: VideoView.bounds.height)
        //preview.videoGravity = .resizeAspect
        //preview.videoGravity = .resize
        return preview
    }()
    
    private let videoOutput = AVCaptureVideoDataOutput()
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Singleton.sharedInstance.reset()
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
        } catch {
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
                let redArray = redVector.map({ KotlinFloat.init(float: $0) })
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
            
            self.updateProgress()
            
            if (frameConsumerStatus == "IN_PROGRESS") {
                // TODO validate intermediate data here
                // Here we update the process status text
                DispatchQueue.global().async {
                    DispatchQueue.main.async { () -> Void in
                        self.resultView.text = "Process status: measurement in progress..."
                        self.validationView.text = ""
                    }
                }
            } else if (frameConsumerStatus == "START_CALCULATING") {
                self.endCapture()
                self.proceedToResults()
            } else if (frameConsumerStatus == "MEASUREMENT_FAILED") {
                DispatchQueue.main.sync {
                    //Here we update the process status text
                    self.resultView.text = "Process status: Let's try one more time!"
                }
            }
        }
    }
    
    private func updateProgress() -> Void {
        //Here we update the progress bar
        DispatchQueue.global().async {
            DispatchQueue.main.async { () -> Void in
                let count = Singleton.sharedInstance.frameConsumer.getVitalsFramesData().counter
                self.progress.setProgress(Float(count) / Float(VitalsScannerSDK.shared.MEASUREMENT_COUNT), animated: false)
            }
        }
    }
    
    private func endCapture() -> Void {
        DispatchQueue.global().sync {
            DispatchQueue.main.sync {
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
    }
    
    private func proceedToResults() -> Void {
        DispatchQueue.main.sync {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "Results") as? ViewControllerResults
            else { return }
            nextViewController.modalPresentationStyle = .fullScreen
            self.present(nextViewController, animated: true, completion: nil)
        }
    }
    
    func getCurrentTimestampInMillis() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    func log(text: String, pauseLog: Bool) {
        let newDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("HH:mm:ss")
        let displayDate = dateFormatter.string(from: newDate) + ": "
        
        let newLogText = (self.resultView.text ?? "\n") + displayDate + text + "\n"
        
        print(newLogText)
        self.resultView.text = newLogText
        self.view.bringSubviewToFront(self.resultView)
        let range = NSMakeRange(self.resultView.text.count*20, 0)
        self.resultView.scrollRangeToVisible(range)
    }
    
    @objc func savedImage(_ im:UIImage, error:Error?, context:UnsafeMutableRawPointer?) {
        if let err = error {
            print(err)
            return
        }
        print("success")
    }
    
    func getArrayOfBytesFromImage(imageData:NSData) -> Array<UInt8> {
        
        // the number of elements:
        let count = imageData.length / MemoryLayout<Int8>.size
        
        // create array of appropriate length:
        var bytes = [UInt8](repeating: 0, count: count)
        
        // copy bytes into array
        imageData.getBytes(&bytes, length:count * MemoryLayout<Int8>.size)
        
        var byteArray:Array = Array<UInt8>()
        
        for i in 0 ..< count {
            byteArray.append(bytes[i])
        }
        return byteArray
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


class ViewControllerResults: UIViewController {
    @IBOutlet var SpO2: UILabel!
    @IBOutlet var Respiration: UILabel!
    @IBOutlet var HeartRate: UILabel!
    @IBOutlet var BloodPressure: UILabel!
//    Uncomment to switch on RISK level
//    @IBOutlet var riskLevel: UILabel!
    @IBOutlet var pulsePressure: UILabel!
    @IBOutlet var stress: UILabel!
    @IBOutlet var reflectionIndex: UILabel!
    @IBOutlet var hrv: UILabel!
    @IBOutlet var lasi: UILabel!
    @IBOutlet var Glucose: UILabel!
    @IBOutlet var StartAgain: UIButton!
    @IBOutlet var CollectData: UIButton!
    
    var existingPatientResponse: [User_] = []
    var existingPatient: User_?
    var newPatient: CreatedUser?
    var animationTimer: Timer?
    
    override func viewDidLoad() {
        StartAgain.isEnabled = false
        CollectData.isEnabled = false
        
        if (!Singleton.sharedInstance.dataProcessed) {
            self.animateProgress()
            self.calculateVitals()
            self.calculateGlucose()
        } else {
            self.presentVitals()
            self.presentGlucose()
        }
        super.viewDidLoad()
    }
    
    private func calculateVitals() -> Void {
        DispatchQueue.global().async {
            let vitalSignProcessor = Singleton.sharedInstance.vitalSignProcessor
            Singleton.sharedInstance.vitalSignProcessor.process(framesData: Singleton.sharedInstance.frameConsumer.getVitalsFramesData())
            
            // Putting values to Singleton to show them on viewController
            Singleton.sharedInstance.SpO2 = vitalSignProcessor.getSPo2Value()
            Singleton.sharedInstance.Respiration = vitalSignProcessor.getBreathValue()
            Singleton.sharedInstance.HeartRate = (Int(vitalSignProcessor.getBeatsValue()) ?? 0) == 0 ? "0" : String((Int(vitalSignProcessor.getBeatsValue()) ?? 0))
            Singleton.sharedInstance.BloodPressure = "\(vitalSignProcessor.getSPValue())/\(vitalSignProcessor.getDPValue())"
            Singleton.sharedInstance.SBP = vitalSignProcessor.getSPValue()
            Singleton.sharedInstance.DBP = vitalSignProcessor.getDPValue()
            Singleton.sharedInstance.lasi = vitalSignProcessor.getLasiValue()
            Singleton.sharedInstance.reflectionIndex = vitalSignProcessor.getReflectionIndexValue()
            Singleton.sharedInstance.pulsePressure = vitalSignProcessor.getPulsePressureValue()
            Singleton.sharedInstance.stress = vitalSignProcessor.getStressValue()
            Singleton.sharedInstance.hrv = vitalSignProcessor.getHrvValue()
            
            DispatchQueue.main.sync {
                self.presentVitals()
            }
        }
    }
    

    private func calculateGlucose() -> Void {
        DispatchQueue.global().async {
            // Start processing
            let vitalSignProcessor = Singleton.sharedInstance.vitalSignProcessor
            let glucoseLevelProcessor = Singleton.sharedInstance.glucoseProcessor
            glucoseLevelProcessor.process(framesData: Singleton.sharedInstance.frameConsumer.getGlucoseFrameData())
            
            let glucoseMin = glucoseLevelProcessor.getGlucoseMinValue()
            let glucoseMax = glucoseLevelProcessor.getGlucoseMaxValue()
            let glucoseMean = (glucoseMin + glucoseMax) / 2
            let risk = vitalSignProcessor.getRiskLevelValue()
            var riskLevel = RiskLevel.unknown

            if (risk != nil) {
                let riskLevelValue = VitalsRiskLevelIOSKt.getVitalsWithGlucose(vitalsRiskLevel: risk!, glucose: Double(glucoseMean))
                riskLevel = VitalsRiskLevelKt.getRiskLevel(riskGrades: riskLevelValue)
            }
            
            Singleton.sharedInstance.glucose = "[\(glucoseMin) - \(glucoseMax)]"
            Singleton.sharedInstance.glucoseMean = glucoseMean
            Singleton.sharedInstance.riskLevel = riskLevel.name
            Singleton.sharedInstance.dataProcessed = true
            
            DispatchQueue.main.sync {
                self.stopAnimateProgress()
                self.presentGlucose()
            }
        }
    }
    
    private func presentVitals() {
        // Showing results in main thread
        self.SpO2.text = Singleton.sharedInstance.SpO2
        self.Respiration.text = Singleton.sharedInstance.Respiration == "0" ? "N/A" : Singleton.sharedInstance.Respiration
        self.HeartRate.text = Singleton.sharedInstance.HeartRate == "0" ? "N/A" : Singleton.sharedInstance.HeartRate
        self.BloodPressure.text = Singleton.sharedInstance.BloodPressure
//        Uncomment to switch on RISK level
//        self.riskLevel.text = Singleton.sharedInstance.riskLevel
        self.pulsePressure.text = Singleton.sharedInstance.pulsePressure
        self.hrv.text = Singleton.sharedInstance.hrv
        self.lasi.text = Singleton.sharedInstance.lasi
        self.stress.text = Singleton.sharedInstance.stress
        self.reflectionIndex.text = Singleton.sharedInstance.reflectionIndex
    }
    
    
    private func presentGlucose() {
        // Showing result in main thread
        self.Glucose.textColor = UIColor.label
        self.Glucose.textAlignment = NSTextAlignment.right
        self.Glucose.text = Singleton.sharedInstance.glucose
//        Uncomment to switch on RISK level
//        self.riskLevel.text = Singleton.sharedInstance.riskLevel
        self.StartAgain.isEnabled = true
        self.CollectData.isEnabled = true
    }
    
    func animateProgress() {
        let text = "Processing"
        var dotCount = 0
        
        self.Glucose.textAlignment = NSTextAlignment.left
        self.Glucose.textColor = UIColor.systemBlue

        DispatchQueue.main.async {
            self.animationTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) {_ in
                dotCount += 1
                let dots = String(repeating: ".", count: dotCount % 4)
                self.Glucose.text = "\(text)\(dots)"
            }
        }
        self.animationTimer?.fire()
    }
    
    func stopAnimateProgress() {
        self.Glucose.textAlignment = NSTextAlignment.right
        self.animationTimer?.invalidate()
    }
}

class ViewControllerCollectData: UIViewController {
    private var patient: Patient?
    @IBOutlet var bloodOxygen: UILabel!
    @IBOutlet var heartRate: UILabel!
    @IBOutlet var respirationRate: UILabel!
    @IBOutlet var bloodPressure: UILabel!
    @IBOutlet var glucoseLevels: UILabel!
    @IBOutlet var bloodOxygenField: UITextField!
    @IBOutlet var heartRateField: UITextField!
    @IBOutlet var respirationRateField: UITextField!
    @IBOutlet var glucoseLevelsField: UITextField!
    @IBOutlet var bloodPressureField: UITextField!
    @IBOutlet var commentField: UITextField!
    @IBOutlet var collectDataButton: UIButton!
    @IBAction func collectDataButtonTap(sender: UIButton) {
        let isCollected = collectData()

        if (isCollected) {
            sender.setTitle("Success", for: UIControl.State.normal)
            sender.isEnabled = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        bloodOxygen.text = Singleton.sharedInstance.SpO2
        heartRate.text = Singleton.sharedInstance.HeartRate == "0.00" ? "N/A" : Singleton.sharedInstance.HeartRate
        respirationRate.text = Singleton.sharedInstance.Respiration == "0.00" ? "N/A" : Singleton.sharedInstance.Respiration
        bloodPressure.text = Singleton.sharedInstance.BloodPressure
        glucoseLevels.text = Singleton.sharedInstance.glucose
        self.patient = Patient.load()
        print("Will collect real data for: \n \(self.getInferredResults()) \n \(self.patient)")
    }
    
    func getInferredResults() -> VitalsDto {
        let vitalSignProcessor = Singleton.sharedInstance.vitalSignProcessor
        let glucoseLevelProcessor = Singleton.sharedInstance.glucoseProcessor
        
        return VitalsDto(
            bps: getIntOrMinusOne(from: vitalSignProcessor.getSPValue()),
            bpd: getIntOrMinusOne(from: vitalSignProcessor.getDPValue()),
            pulse: getIntOrMinusOne(from: vitalSignProcessor.getBeatsValue()),
            respiration: getIntOrMinusOne(from: vitalSignProcessor.getBreathValue()),
            oxygen: getIntOrMinusOne(from: vitalSignProcessor.getSPo2Value()),
            glucoseMin: glucoseLevelProcessor.getGlucoseMinValue(),
            glucoseMax: glucoseLevelProcessor.getGlucoseMaxValue()
        )
    }

    private func collectData() -> Bool {
        let rawData = Singleton.sharedInstance.frameConsumer.getGlucoseFrameData()
        let realVitals = getRealVitals()
        let user = UserParameters(
            height: patient!.patientHeight, weight: patient!.patientWeight,
            age: Int32(patient!.getAge()), gen: Int32(patient!.gender)
        )
        print("Attempting to collect data: \n \(rawData) \n \(self.getInferredResults()) \n \(realVitals) \n \(patient)")
        
        return VitalsScannerSDK.shared.logs.addDataCollectionLog(
            framesData: Singleton.sharedInstance.frameConsumer.getGlucoseFrameData(),
            predicted: self.getInferredResults(),
            real: realVitals,
            user: user,
            comment: commentField.text ?? ""
        )
    }
    
    private func getIntOrMinusOne(from text: String) -> Int32 {
        Int32(text) ?? -1
    }
    
    func parseBloodPressure(from reading: String) -> (systolic: Int32, diastolic: Int32) {
        let components = reading.split(separator: "/")
        guard components.count == 2,
              let systolic = Int32(components[0]),
              let diastolic = Int32(components[1]) else {
            return (-1, -1) // Default values in case of parsing error
        }
        return (systolic, diastolic)
    }
    
    private func getRealVitals() -> VitalsDto {
        guard
            let glucoseText = glucoseLevelsField.text,
            let heartText = heartRateField.text,
            let bloodText = bloodOxygenField.text,
            let respirationText = respirationRateField.text,
            let bloodPressureText = bloodPressureField.text
        else { return VitalsDto(
            bps: -1,
            bpd: -1,
            pulse: -1,
            respiration: -1,
            oxygen: -1,
            glucoseMin: -1,
            glucoseMax: -1
        )}
        
        let realGlucose = getIntOrMinusOne(from: glucoseText)
        let realPulse = getIntOrMinusOne(from: heartText)
        let realOxygen = getIntOrMinusOne(from: bloodText)
        let realRespiration = getIntOrMinusOne(from: respirationText)
        let parsedBloodPressure = parseBloodPressure(from: bloodPressureText)
        
        return VitalsDto(
            bps: parsedBloodPressure.systolic,
            bpd: parsedBloodPressure.diastolic,
            pulse: realPulse,
            respiration: realRespiration,
            oxygen: realOxygen,
            glucoseMin: realGlucose,
            glucoseMax: realGlucose
        )
    }
}


//so tht we can share the data between app views (screens) and view controllers
class Singleton {
    let frameConsumer = DefaultFrameConsumerIOS()
    let vitalSignProcessor = VitalSignProcessorIOS()
    let glucoseProcessor = GlucoseLevelProcessorIOS()
    
    var dataProcessed: Bool = false    
    var SpO2: String = "0.00"
    var glucose: String = "0.00"
    var glucoseMean: Int32 = 0
    var Respiration: String = "0.00"
    var HeartRate: String = "0.00"
    var BloodPressure: String = "0.00"
    var SBP: String = "0"
    var DBP: String = "0"
    var riskLevel: String = "UNKNOWN"
    var pulsePressure: String = "0.00"
    var stress: String = "0.00"
    var reflectionIndex: String = "0.00"
    var hrv: String = "0.00"
    var lasi: String = "0.00"
    
    static let sharedInstance = Singleton()
    
    func reset() {
        frameConsumer.resetFramesData()
        dataProcessed = false
    }
    
    private init() {
    }
}
