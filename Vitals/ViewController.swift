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

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{

    @IBOutlet var textView: UITextView!
    @IBOutlet var resultView: UITextView!
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var VideoView: UIView!

    let startTime = Date().timeIntervalSince1970

    //Session to start video capturing
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        return preview
    }()
    
    private let videoOutput = AVCaptureVideoDataOutput()
    
    //pass user related data here. Height in cm, weight in kg, age in years, gender: 1 - male, 2 - female
    private let vsProcessor = VitalSignsProcessorIOS(user: User(height: 180, weight: 72.5, age: 39, gen: 1))


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addCameraInput()
        self.addPreviewLayer()
        self.addVideoOutput()
        self.toggleTorch(on: true)
              
        self.captureSession.startRunning()
        self.captureSession.sessionPreset = AVCaptureSession.Preset.low;
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
        let dataBuffer = src_buff!.assumingMemoryBound(to: UInt8.self)

        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            
        //Doing some magic with images here. In fact we're extracting red, green and blue averages of each frame and then passign this to SDK.
        //You can just copy/pase this part of the code
        //-->
        let numberOfPixels = height * width
        var greenVector:[Float] = Array(repeating: 0.0, count: numberOfPixels)
        var blueVector:[Float] = Array(repeating: 0.0, count: numberOfPixels)
        var redVector:[Float] = Array(repeating: 0.0, count: numberOfPixels)
        
        vDSP_vfltu8(dataBuffer, 4, &blueVector, 1, vDSP_Length(numberOfPixels))
        vDSP_vfltu8(dataBuffer+1, 4, &greenVector, 1, vDSP_Length(numberOfPixels))
        vDSP_vfltu8(dataBuffer+2, 4, &redVector, 1, vDSP_Length(numberOfPixels))
        var redAverage:Float = 0.0
        var blueAverage:Float = 0.0
        var greenAverage:Float = 0.0
        
        vDSP_meamgv(&redVector, 1, &redAverage, vDSP_Length(numberOfPixels))
        vDSP_meamgv(&greenVector, 1, &greenAverage, vDSP_Length(numberOfPixels))
        vDSP_meamgv(&blueVector, 1, &blueAverage, vDSP_Length(numberOfPixels))
        //<--
        
        let endTime = Date().timeIntervalSince1970
        let diff = endTime - startTime
        

        do {
            var status: String
            //Send average colour of RGB for ech frame to SKD to prcess it and return the status which we check below
            status = try vsProcessor.processImageRGB(red: Double(redAverage), green: Double(greenAverage), blue: Double(blueAverage)).name
                            DispatchQueue.global().async {
                DispatchQueue.main.async { () -> Void in
                    self.progress.setProgress(Float(diff*0.025), animated: true)
                }
            }
            //For each ststus we reflect it on the status text on the screen in asynchronous mode
            if(status == "IN_PROGRESS"){
                DispatchQueue.global().async {
                    DispatchQueue.main.async { () -> Void in
                        self.resultView.text = "Process status: measurement in progress..."
                    }
                }
            }
            //If status is PROCESS_FINISHED, we can request SDK for results
            if(status == "PROCESS_FINISHED") {
                DispatchQueue.global().async {
                    DispatchQueue.main.async { () -> Void in
                        self.resultView.text = "Process status: Almost done..."
                    }
                }
                
                DispatchQueue.main.sync {
                    //Here we get values of calculcated results from SDK
                    let ResultedO2 : String = "O2="+self.vsProcessor.getSPo2Value()+"\n"
                    let ResultedBeats : String = "Beats="+String((Int(self.vsProcessor.getBeatsValue()) ?? 0))+"\n"
                    let ResultedBreath : String = "Breath="+self.vsProcessor.getBreathValue()+"\n"
                    let ResultedDP : String = "DP="+self.vsProcessor.getDPValue()+"\n"
                    let ResultedSP : String = "SP="+self.vsProcessor.getSPValue()+"\n"
                    
                    print(ResultedO2)
                    print(ResultedBeats)
                    print(ResultedBreath)
                    print(ResultedDP)
                    print(ResultedSP)
                                            
                    //putting values to Singleton to show them on viewController
                    Singleton.sharedInstance.SpO2 = self.vsProcessor.getSPo2Value()
                    Singleton.sharedInstance.Respiration = self.vsProcessor.getBreathValue()
                    Singleton.sharedInstance.HeartRate = String((Int(self.vsProcessor.getBeatsValue()) ?? 0))
                    Singleton.sharedInstance.BloodPressure = self.vsProcessor.getSPValue()+"/"+self.vsProcessor.getDPValue()
                    Singleton.sharedInstance.SBP = self.vsProcessor.getSPValue()
                    Singleton.sharedInstance.DBP = self.vsProcessor.getDPValue()

                    
                    //programmatically show results view
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)

                    let nextViewController = storyBoard.instantiateViewController(withIdentifier: "Results")
                    self.present(nextViewController, animated:true, completion:nil)
                    self.captureSession.stopRunning()
                }
                
            }else if (status != "NEED_MORE_IMAGES") {
                DispatchQueue.main.sync {
                    if (status == "MEASUREMENT_FAILED") {
                        //Here we update the process status text
                        DispatchQueue.global().async {
                            DispatchQueue.main.async { () -> Void in
                                self.resultView.text = "Process status: Let's try one more time!"
                            }
                        }
                    }
                }
            }else{
                DispatchQueue.global().async {
                    DispatchQueue.main.async { () -> Void in
                        self.resultView.text = "Process status: Something went not so correct. Let's try again!"
                    }
                }
                DispatchQueue.main.sync {
                    if (status == "MEASUREMENT_FAILED") {
                        self.log(text: "MEASUREMENT_FAILED", pauseLog: false)
                    }else{
                        self.log(text: status+", redAVG="+String(redAverage)+", greenAvg="+String(greenAverage)+", blueAvg="+String(blueAverage), pauseLog: false)
                    }
                }
            }
            
        }
        catch {
            // Couldn't create player object, log the error
            print("Error=\(error)")
        }
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
 
    
    //Functions to work with camera
    //-->
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
    //<--
    
    
    //Toggling on a torch as we need light!
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

//Show results here
class ViewControllerResults: UIViewController{
    @IBOutlet var SpO2: UILabel!
    @IBOutlet var Respiration: UILabel!
    @IBOutlet var HeartRate: UILabel!
    @IBOutlet var BloodPressure: UILabel!
        
    override func viewDidLoad()
    {
        SpO2.text = Singleton.sharedInstance.SpO2
        Respiration.text = Singleton.sharedInstance.Respiration
        HeartRate.text = Singleton.sharedInstance.HeartRate
        BloodPressure.text = Singleton.sharedInstance.BloodPressure
        super.viewDidLoad()
    }
}


//This is just to show a version so you can skip that part
class ViewControllerStart: UIViewController{
    @IBOutlet var Version: UILabel!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.autoresizesSubviews = true
        Version.text = getVersion()
    }
    
  
}


//get version number
public func getVersion() -> String {
    let version: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"]! as! String
    let boundleVersion: String = Bundle.main.infoDictionary!["CFBundleVersion"]! as! String
    return version + "(" + boundleVersion + ")"
}

//Untilizing singleton o that we can share the data between app views (screens) and view controllers
class Singleton{
    var SpO2: String = "0"
    var Respiration: String = "0"
    var HeartRate: String = "0"
    var BloodPressure: String = "0"
    var SBP : String = "0"
    var DBP : String = "0"
    
    static let sharedInstance = Singleton()
    private init(){
        
    }
    
}
