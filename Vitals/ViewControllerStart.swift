//
//  ViewControllerStart.swift
//  Vitals
//
//  Created by Artur Latypov on 3/30/24.
//  Copyright © 2024 Anurag Ajwani. All rights reserved.
//

import SwiftUI

class ViewControllerStart: UIViewController{
    @IBOutlet var NextButton: UIButton!
    @IBOutlet var ChangeMyDataButton: UIButton!
    @IBOutlet var Version: UILabel!
    @IBOutlet var Logo: UIImage!
    var patient: Patient = Patient.load()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.autoresizesSubviews = true
        //view.transform = CGAffineTransform.identity.scaledBy(x: 2, y: 2)
        NextButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        setVersionNumber()
        ChangeMyDataButton.isHidden = !setChangeMyDataButtonVisibility()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchCount = touches.count
        let touch = touches.first
        let tapCount = touch!.tapCount
        
        if(tapCount == 10) {
            self.patient.reset()
            self.patient.save()
            ChangeMyDataButton.isHidden = !setChangeMyDataButtonVisibility()
            showToast(message: "User data was cleared.",font: .systemFont(ofSize: 12.0))
        }
        
    }
    
    func showToast(message : String, font: UIFont) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 9.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    @IBAction func buttonAction(_ sender: UIButton) {
        if (setChangeMyDataButtonVisibility() == true)  {
            self.performSegue(withIdentifier: "ToMesurement", sender: nil)
        }
        else {
            self.performSegue(withIdentifier: "ToUserData", sender: nil)
        }
    }
    
    func setVersionNumber(){
        let version: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"]! as! String
        let boundleVersion: String = Bundle.main.infoDictionary!["CFBundleVersion"]! as! String
        Version.text = version + "(" + boundleVersion + ")"
    }
    
    func setChangeMyDataButtonVisibility() -> Bool {
        return self.patient.isValid()
    }
    
    
}
