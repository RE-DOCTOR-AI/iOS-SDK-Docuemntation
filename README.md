# iOS-SDK-Documentation
## Overview of the SDK functionality
iOS SDK functionality allows iOS developers to add a Vitals & Glucose measurement functionality into their apps by using RE.DOCTOR iOS SDK.
The SDK accepts a few parameters as input. It also requires to have some end user data like: Age, Height, Weight & Gender.
SDK requires at least 40 seconds of camera and flash to be on to capture video which is converted to RGB array on the fly which allows to make calculations of Vitals and Glucose.

## Tutorials
### Work with existing demo app
1. Download the repo
2. Open it in XCode
3. Send a request to get the SDK files
4. Put the SDK files file to the root folder of the app
5. Run the App

### Install SDK to a new project
1. To install the SDK move the SDK files into the root folder of your project directory.
* Open your project in XCode
* Go to “Targets“ → “General“ tab

#### Work with SDK in code
Easiest way is to see how it's done on the example app here: [https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/blob/main/Vitals/ViewController.swift](https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/blob/v1.4.0/Vitals/ViewController.swift)
1. Allow application to work with camera
* Go to “Info“
* Add a key “Privacy - Camera Usage Description“
<img width="700" alt="image" src="https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/assets/125552714/9110bfff-e623-4cd9-a347-713828f4b805"><br/>
2. To work with the framework in the code you need to import it using ```import shared```: [https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/blob/main/Vitals/ViewController.swift#L10](https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/blob/v1.4.0/Vitals/ViewController.swift#L10C14-L10C14)

##### Get results
On the class above you can see the status ```status == "PROCESS_FINISHED"```. So once this status is reached you can get values from the library.
You can see it here [https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/blob/main/Vitals/ViewController.swift#L115](https://github.com/RE-DOCTOR-AI/iOS-SDK-Documentation/blob/v1.4.0/Vitals/ViewController.swift#L190)
               
#### Keep in mind
##### Metric vs Imperial
Library needs some patient data in a metric system so use kilograms(kg) and centimetres (cm). Here is the list:
1. Height (cm)
2. Weight (kg)
3. Age (years)
4. Gender (1 - Male, 2 - Female). We are sorry to ask you to chose only between those two numbers but calculations are depend on them.

In case you have imperial measurement system in your apps you can convert that data to metric.

##### Process duration
Remember that process of measurement lasts for 40 seconds. 

### Troubleshooting
Debug release of SDK writes some outputs to logs so you can see if there are any issues.
## Point of Contact for Support
In case of any questions, please contact timur@re.doctor
## Version details
Current version is 1.4.0(19) has a  functionality to measure several parameters including: 

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

