//
//  ViewController1.swift
//  Vitals
//
//  Created by Artur Latypov on 3/30/24.
//  Copyright © 2024 Anurag Ajwani. All rights reserved.
//

import Foundation
import UIKit

class ViewControllerPatientParameters: UIViewController, UITextFieldDelegate {
    @IBOutlet var firstNameInput: UITextField!
    @IBOutlet var lastNameInput: UITextField!
    @IBOutlet var nextButton: UIButton!
    
    // Height controls
    @IBOutlet var heightInput: UITextField!
    @IBOutlet var heightInputLabel: UILabel!
    @IBOutlet var heightInputErrorLabel: UILabel!
    var heightValidated: Bool = false
    
    // Wight controls
    @IBOutlet var weightInput: UITextField!
    @IBOutlet var weightInputLabel: UILabel!
    @IBOutlet var weightInputErrorLabel: UILabel!
    var weightValidated: Bool = false
    
    // Date of birth controls
    @IBOutlet var dateOfBirthPicker: UIDatePicker!
    @IBOutlet var ageLabel: UITextField!
    @IBOutlet var ageErrorLabel: UILabel!
    var ageValidated: Bool = false
    
    // Gender controls
    @IBOutlet var genderLabel: UITextField!
    @IBOutlet var genderErrorLabel: UILabel!
    var genderValidated: Bool = false
    
    @IBOutlet var useImperialSystem: UISwitch!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var genderSegmentControl: UISegmentedControl!
    
    private let errorMessage = UILabel()
    private var patient: Patient = Patient.load()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        heightInput.delegate = self
        weightInput.delegate = self
        ageLabel.delegate = self
        genderLabel.delegate = self
        useImperialSystem.addTarget(self, action: #selector(onSwitchValueChanged), for: UIControl.Event.valueChanged)
        dateOfBirthPicker.addTarget(self, action: #selector(onDateValueChanged(_:)), for: .valueChanged)
        
        print("Loaded patient \(self.patient.toString())")
        let gender = self.patient.gender
        let isImperial = self.patient.isImperial
        let dateOfBirth = self.patient.dateOfBirth
        
        firstNameInput.text = self.patient.firstName
        lastNameInput.text = self.patient.lastName
        heightInput.text = String(self.patient.patientHeight)
        weightInput.text = String(self.patient.patientWeight)
        ageLabel.text = String(self.patient.getAge())
        genderLabel.text = String(gender)
        
        switch gender {
        case 1:
            genderSegmentControl.selectedSegmentIndex = 0
        case 2 :
            genderSegmentControl.selectedSegmentIndex = 1
        default:
            break
        }
        
        useImperialSystem.isOn = isImperial
        dateOfBirthPicker.date = dateOfBirth
        dateOfBirthPicker.date.description.reversed()
        
        //Hiding error lables
        heightInputErrorLabel.isHidden = true
        weightInputErrorLabel.isHidden = true
        ageErrorLabel.isHidden = true
        genderErrorLabel.isHidden = true
        
        setHeightWeightLables(isImperial)
        setupTextFields()
        hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        genderSegmentControl.addTarget(self, action: #selector(segmentControllClick), for: UIControl.Event.valueChanged )
    }
    
    @objc func segmentControllClick(_ sender: Any) {
        switch genderSegmentControl.selectedSegmentIndex {
        case 0:
            genderLabel.text = "1"
        case 1 :
            genderLabel.text = "2"
        default:
            break
        }
        patientGenderDidChange(ageLabel)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else {
            // if keyboard size is not available for some reason, dont do anything
            return
        }
        
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height , right: 0.0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        
        // reset back the content inset to zero after keyboard is gone
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        patientHeightDidChange(heightInput)
        patientWeightDidChange(weightInput)
        patientAgeDidChange(ageLabel)
        patientGenderDidChange(genderLabel)
        onDateValueChanged(dateOfBirthPicker)
        
        if (
            heightValidated == false
            || weightValidated == false
            || ageValidated == false
            || genderValidated == false
        ) {
            //Fire fileds validation
            let alertController = UIAlertController(
                title: "Fields validation", message: "Please fill fields correctly", preferredStyle: .alert)
            let defaultAction = UIAlertAction(
                title: "Close", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            present(alertController, animated: true, completion: nil)
            return false
        } else {
            return true
        }
    }
    
    @objc private func onDateValueChanged(_ datePicker: UIDatePicker) {
        self.patient.dateOfBirth = datePicker.date
        ageLabel.text = String(self.patient.getAge())
        patientAgeDidChange(ageLabel)
    }
    
    
    //switching between imperial and metric systems
    @objc func onSwitchValueChanged(mySwitch: UISwitch) {
        self.patient.setIsImperial(mySwitch.isOn)
        weightInput.text = String(self.patient.patientWeight)
        heightInput.text = String(self.patient.patientHeight)
        
        setHeightWeightLables(mySwitch.isOn)
        //Fire fileds validation
        patientHeightDidChange(heightInput)
        patientWeightDidChange(weightInput)
        patientAgeDidChange(ageLabel)
        patientGenderDidChange(genderLabel)
    }
    
    private func setHeightWeightLables(_ isImperialSwitchedOn: Bool) {
        if (isImperialSwitchedOn) {
            heightInputLabel.text = "Height (ft)"
            weightInputLabel.text = "Weight (lb)"
        } else {
            heightInputLabel.text = "Height (cm)"
            weightInputLabel.text = "Weight (kg)"
        }
    }
    /**
     * Called when 'return' key pressed. return NO to ignore.
     */
    // https://programmingwithswift.com/move-to-next-text-field-with-swift/
    private func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let nextTag = textField.tag + 1
        
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // Persist entered values so that we can use it later
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.patient.save()
    }
    
   
    // Validation block
    @objc func patientHeightDidChange(_ textField: UITextField) -> Bool {
        heightInput.text = heightInput.text?.trimmingCharacters(in: .whitespaces)
        heightInput.text = heightInput.text?.trimmingCharacters(in: .symbols)
        self.patient.patientHeight = textField.text?.toDouble() ?? 0.0

        // if we are on Imperial than change threashold for Height
        if (self.patient.isImperial) {
            heightValidated = heightInput.isValid(from: 1.64, to: 8.2, errorLabel: heightInputErrorLabel)
        } else {
            heightValidated = heightInput.isValid(from: 50, to: 250, errorLabel: heightInputErrorLabel)
        }
        heightInputErrorLabel.isHidden = heightValidated
        return heightValidated
    }
    
    @objc func patientWeightDidChange(_ textField: UITextField) -> Bool {
        weightInput.text = weightInput.text?.trimmingCharacters(in: .whitespaces)
        weightInput.text = weightInput.text?.trimmingCharacters(in: .symbols)
        self.patient.patientWeight = textField.text?.toDouble() ?? 0.0
        
        //if we are on Imperial than change threashold for Height
        if (self.patient.isImperial) {
            weightValidated = weightInput.isValid(from: 22, to: 660, errorLabel: weightInputErrorLabel)
        } else {
            weightValidated = weightInput.isValid(from: 10, to: 300, errorLabel: weightInputErrorLabel)
        }
        weightInputErrorLabel.isHidden = weightValidated
        return weightValidated
    }
    
    @objc func patientAgeDidChange(_ textField: UITextField) -> Bool {
        ageValidated = ageLabel.isValid(from: 18, to: 120, errorLabel: ageErrorLabel)
        ageErrorLabel.isHidden = ageValidated
        return ageValidated
    }
    
    @objc func patientGenderDidChange(_ textField: UITextField) -> Bool {
        //if we are on Imperial than change threashold for Height
        genderValidated = genderLabel.isGenderValid(from: 1, to: 2, errorLabel: genderErrorLabel)
        genderErrorLabel.isHidden = genderValidated
        self.patient.gender = Int(textField.text!)!
        return genderValidated
    }
    
    @objc func onFirstNameChange(_ textField: UITextField) -> Bool {
        self.patient.firstName = textField.text!
        return true
    }
    
    @objc func onLastNameChange(_ textField: UITextField) -> Bool {
        self.patient.lastName = textField.text!
        return true
    }
    
    func setupTextFields() {
        firstNameInput.addTarget(self,
                            action: #selector(self.onFirstNameChange(_:)),
                            for: UIControl.Event.editingChanged)
        
        lastNameInput.addTarget(self,
                            action: #selector(self.onLastNameChange(_:)),
                            for: UIControl.Event.editingChanged)
        
        heightInput.addTarget(self,
                                action: #selector(self.patientHeightDidChange(_:)),
                                for: UIControl.Event.editingChanged)
        
        weightInput.addTarget(self,
                                action: #selector(self.patientWeightDidChange(_:)),
                                for: UIControl.Event.editingChanged)
        
        ageLabel.addTarget(self,
                             action: #selector(self.patientAgeDidChange(_:)),
                             for: UIControl.Event.editingChanged)
        
        genderLabel.addTarget(self,
                                action: #selector(self.patientGenderDidChange(_:)),
                                for: UIControl.Event.editingChanged)
    }
}

extension String {
    func toDouble(or defaultValue: Double = 0.0) -> Double {
        return Double(self) ?? defaultValue
    }
}

extension UITextField {
    func isValid(from: Float, to: Float, errorLabel: UILabel) -> Bool {
        guard let text = self.text,
              !text.isEmpty else {
            errorLabel.text="Value should be between " + String(from) + " and " + String(to)
            return false
        }
        
        if let floatText: Float = Float(text) {
            if (floatText >= from && floatText <= to) {
                return true
            } else {
                errorLabel.text="Value should be between " + String(from) + " and " + String(to)
                return false
            }
        } else {
            errorLabel.text="Value should be between " + String(from) + " and " + String(to)
            return false
        }
    }
    
    func isGenderValid(from: Float, to: Float, errorLabel: UILabel) -> Bool{
        guard let text = self.text,
              !text.isEmpty else {
            //errorLabel.text="Value should be " + String(from) + " or " + String(to)
            errorLabel.text="Value should be Male or Female"
            return false
        }
        if let FloatText: Float = Float(text) {
            if (FloatText == from || FloatText == to){
                return true
            }else{
                //errorLabel.text="Value should be " + String(from) + " or " + String(to)
                errorLabel.text="Value should be Male or Female"
                return false
            }
        } else {
            //errorLabel.text="Value should be " + String(from) + " or " + String(to)
            errorLabel.text="Value should be Male or Female"
            return false
        }
    }
}
