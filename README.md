# iOS-SDK-Documentation
## Overview of the SDK functionality
iOS SDK functionality allows iOS developers to add a Vitals & Glucose measurement functionality into their apps by using RE.DOCTOR iOS SDK.
The SDK accepts a few parameters as input. It also requires to have some end user data like: Age, Height, Weight & Gender.
SDK requires at least 40 seconds of camera and flash to be on to capture video which is converted to RGB array on the fly which allows to make calculations of Vitals and Glucose.

## Tutorials
### Work with existing demo app
1. Download the repo
2. Open it in XCode
3. Send a request to get the SDK file "shared.framework"
4. Put the "shared.framework" file to the root folder of the app
5. Do steps #1 and #2 from the instruction below
6. Run the App

### Install SDK to a new project
1. To install the SDK move the shared.framework file into the root folder of your project directory.
* Open your project in XCode
* Go to “Targets“ → “General“ tab
* Scroll to “Frameworks, Libraries, and Embeded Content“ 
<img width="700" alt="image" src="https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/assets/125552714/c948c7af-39cc-4da1-bbc1-907ff5285f65"><br/>
* Click on “+” and choose “Add Files …” option
<img width="700" alt="image" src="https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/assets/125552714/397eacc0-4ddb-4c61-828c-50d1d3cd9510"><br/>
* Choose the “shared.framework“ file<br/>
<img width="700" alt="image" src="https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/assets/125552714/51a696b3-f622-476c-a811-6ab1a7a9ad68"><br/>
2. Add path to the “shared.framework” in your project
* Go to “Target“ → “Build settings“ tab
* Scroll to “Search Paths“ and double-click on “Processing field“ in “Framework Search Paths“
<img width="700" alt="image" src="https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/assets/125552714/4a6eeb2e-4590-4a21-861c-1a516cb43884"><br/>
* Click on “+” sign 
* Add “$(PROJECT_DIR)“ value into the field
<img width="700" alt="image" src="https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/assets/125552714/333879ec-36f5-4907-8e1a-45cec927628b"><br/>
* Press Enter and click on “Framework Search Paths”
* You should be able to see values for “Debug” and “Release” settings
<img width="700" alt="image" src="https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/assets/125552714/32617b5f-6dc9-40eb-bd47-546bb808e78b"><br/>
* Now you should be able to call functions from the “shared.framework”

#### Work with SDK in code
Easiest way is to see how it's done on the example app here: https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/blob/main/Vitals/ViewController.swift
1. Allow application to work with camera
* Go to “Info“
* Add a key “Privacy - Camera Usage Description“
<img width="700" alt="image" src="https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/assets/125552714/9110bfff-e623-4cd9-a347-713828f4b805"><br/>
2. To work with the framework in the code you need to import it using ```import shared```: https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/blob/main/Vitals/ViewController.swift#L10
```swift
import UIKit
import WebKit
import AVFoundation
import VideoToolbox
import shared
import Accelerate
import CoreMedia.CMFormatDescription
```
4. In your ```ViewController``` you need to do the following:
* implement ```class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate``` see it here https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/blob/main/Vitals/ViewController.swift#LL14C1-L14C85
* create an instance of a vital signs processor class and pass there user data ```private let vsProcessor = VitalSignsProcessorIOS(user: User(height: 180, weight: 72.5, age: 39, gen: 1))``` see it here: https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/blob/main/Vitals/ViewController.swift#L33

```swift
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
```

* call  ```processImageRGB``` in ```VitalSignsProcessorIOS``` which you should use in your iOS app. It accepts the average colour intensity for Red, Green, Blue taken from Image (video camera frame) see it here: https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/blob/main/Vitals/ViewController.swift#L100
* it returns ProcessStatus enum, with 5 statuses:
```
RED_INTENSITY_NOT_ENOUGH("Not good red intensity to process. Should start again"),

MEASUREMENT_FAILED("Measurement Failed. Should Start again"),

IN_PROGRESS("Processing in progress"),

PROCESS_FINISHED("Processing finished"),

NEED_MORE_IMAGES("Need more images to process")
```

##### Get results
On the class above you can see the status ```status == "PROCESS_FINISHED"```. So once this status is reached you can get values from the library.
You can see it here https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/blob/main/Vitals/ViewController.swift#L115
               
#### Keep in mind
##### Metric vs Imperial
Library needs some patient data in a metric system so use kilograms(kg) and centimetres (cm). Here is the list:
1. Height (cm)
2. Weight (kg)
3. Age (years)
4. Gender (1 - Male, 2 - Female). We are sorry to ask you to chose only between those two numbers but calculations are depend on them.

In case you have imperial measurement system in your apps you can convert that data to metric.

##### Process duration
Remember that process of measurement lasts for 40 seconds. You can see the constant ```VITALS_PROCESS_DURATION``` which is stored in the SDK and equals 40 seconds. Which means user have to hold their finder during that time.
### Troubleshooting
Debug release of SDK writes some outputs to logs so you can see if there are any issues.
## Point of Contact for Support
In case of any questions, please contact timur@re.doctor
## Version details
Current version is 1.0.0 (10) has a basic functionality to measure vitals including: 

1. Blood Oxygen
2. Respiration Rate
3. Heart Rate
4. Blood Pressure

## Screenshots
<p float="left">
<img src="https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/assets/125552714/dfa00be5-e4a5-4287-b1dd-3e17b546d5a6" width=15% height=15%>
<img src="https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/assets/125552714/8eac4e37-43d0-490f-be4d-3596887a23fd" width=15% height=15%>
<img src="https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/assets/125552714/b0e64698-2850-4f16-95f5-a045fdb48560" width=15% height=15%>    
<img src="https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/assets/125552714/d33b27b8-fb64-4e61-9c97-4a3063271e91" width=15% height=15%>
</p>

