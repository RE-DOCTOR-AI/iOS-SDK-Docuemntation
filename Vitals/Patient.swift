//
//  Patient.swift
//  Vitals
//
//  Created by Artur Latypov on 3/30/24.
//  Copyright © 2024 Anurag Ajwani. All rights reserved.
//

import Foundation
import SQLite

//this is the change between kg and lbs, 1kg = this amount of lbs
let kgToLbMultiplier: Double = 2.2046226218;

//this is the change between cm and feet
let cmToFeetMultiplier: Double = 0.0328;

class Patient {
    var firstName: String
    var lastName: String
    var patientHeight: Double // Assuming height is in centimeters or inches based on isImperial
    var patientWeight: Double // Assuming weight is in kg or lbs based on isImperial
    var dateOfBirth: Date
    var gender: Int
    var isImperial: Bool
    
    static var db: Connection? = nil
    static let patientsTable = Table("patients")
    // Define the table columns
    static let id = Expression<Int64>("id")
    static let firstNameExp = Expression<String>("firstName")
    static let lastNameExp = Expression<String>("lastName")
    static let patientHeightExp = Expression<Double>("patientHeight")
    static let patientWeightExp = Expression<Double>("patientWeight")
    static let dateOfBirthExp = Expression<Date>("dateOfBirth")
    static let genderExp = Expression<Int>("gender")
    static let isImperialExp = Expression<Bool>("isImperial")
    
    init(firstName: String, lastName: String, patientHeight: Double, patientWeight: Double, dateOfBirth: Date, gender: Int, isImperial: Bool) {
        self.firstName = firstName
        self.lastName = lastName
        self.patientHeight = patientHeight
        self.patientWeight = patientWeight
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.isImperial = isImperial
    }
    
    // Initialize the SQLite connection
    static func initializeDB() {
        do {
            Patient.db = DBHelper.openConnection()
            try Patient.createTable()
        } catch {
            print("Unable to initialize database: \(error)")
            db = nil
        }
    }
    
    static func createTable() throws {
        try db?.run(patientsTable.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .default)
            t.column(firstNameExp)
            t.column(lastNameExp)
            t.column(patientHeightExp)
            t.column(patientWeightExp)
            t.column(dateOfBirthExp)
            t.column(genderExp)
            t.column(isImperialExp)
        })
    }
    
    func isValid() -> Bool {
        let nameDefined = !self.firstName.isEmpty && !self.lastName.isEmpty
        
        return nameDefined && self.patientWeight > 0 && self.patientHeight > 0 && self.getAge() >= 18 && self.getAge() < 100 && self.gender > 0
    }
    
    func reset() -> Void {
        self.firstName = ""
        self.lastName = ""
        self.patientHeight = 0.0
        self.patientWeight = 0.0
        self.dateOfBirth = Date()
        self.gender = 1
        self.isImperial = false
    }
    
    func getAge() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let birthDate = self.dateOfBirth
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 0
    }
    
    func setIsImperial(_ isImperial: Bool) {
        if (self.isImperial == isImperial) {
            return
        }
        
        if isImperial {
            // Convert from metric to imperial
            self.patientHeight = self.centimetersToFeet(self.patientHeight)
            self.patientWeight = self.kilogramsToPounds(self.patientWeight)
        } else {
            // Convert from imperial to metric
            self.patientHeight = self.feetToCentimeters(self.patientHeight)
            self.patientWeight = self.poundsToKilograms(self.patientWeight)
        }
        
        self.isImperial = isImperial
    }
    
    func toString() -> String {
        return "\(self.firstName) \(self.lastName): w=\(self.patientWeight), h=\(self.patientHeight), age=\(self.getAge()), gender=\(self.gender)"
    }
    
    // Converts height from centimeters to feet
    private func centimetersToFeet(_ cm: Double) -> Double {
        return cm * cmToFeetMultiplier
    }
    
    // Converts height from feet to centimeters
    private func feetToCentimeters(_ inches: Double) -> Double {
        return inches / cmToFeetMultiplier
    }
    
    // Converts weight from kilograms to pounds
    private func kilogramsToPounds(_ kilograms: Double) -> Double {
        return kilograms * kgToLbMultiplier
    }
    
    // Converts weight from pounds to kilograms
    private func poundsToKilograms(_ pounds: Double) -> Double {
        return pounds / kgToLbMultiplier
    }
    
    
    func save() {
        if (Patient.db == nil) {
            Patient.initializeDB()
        }
        
        guard let db = Patient.db else {
            print("Database connection is nil.")
            return
        }
        
        do {
            let exists = try db.scalar(Patient.patientsTable.filter(Patient.id == 1).count) > 0
            if exists {
                let update = Patient.patientsTable.filter(Patient.id == 1).update(
                    Patient.firstNameExp <- self.firstName,
                    Patient.lastNameExp <- self.lastName,
                    Patient.patientHeightExp <- self.patientHeight,
                    Patient.patientWeightExp <- self.patientWeight,
                    Patient.dateOfBirthExp <- self.dateOfBirth,
                    Patient.genderExp <- self.gender,
                    Patient.isImperialExp <- self.isImperial
                )
                try db.run(update)
                print("Updated patient record")
            } else {
                let insert = Patient.patientsTable.insert(
                    Patient.id <- 1,
                    Patient.firstNameExp <- self.firstName,
                    Patient.lastNameExp <- self.lastName,
                    Patient.patientHeightExp <- self.patientHeight,
                    Patient.patientWeightExp <- self.patientWeight,
                    Patient.dateOfBirthExp <- self.dateOfBirth,
                    Patient.genderExp <- self.gender,
                    Patient.isImperialExp <- self.isImperial
                )
                try db.run(insert)
                print("Inserted new patient record")
            }
        } catch {
            print("Error saving patient: \(error)")
        }
    }
    
    static func load() -> Patient {
        let defaultPatient = Patient(
            firstName: "",
            lastName: "",
            patientHeight: 0.0,
            patientWeight: 0.0,
            dateOfBirth: Date(),
            gender: 1,
            isImperial: false
        )
        
        guard let db = Patient.db else {
            print("Database connection is nil.")
            return defaultPatient
        }
        
        do {
            if let patientRow = try db.pluck(Patient.patientsTable.filter(Patient.id == 1)) {
                let firstName = patientRow[Patient.firstNameExp]
                let lastName = patientRow[Patient.lastNameExp]
                let patientHeight = patientRow[Patient.patientHeightExp]
                let patientWeight = patientRow[Patient.patientWeightExp]
                let dateOfBirth = patientRow[Patient.dateOfBirthExp]
                let gender = patientRow[Patient.genderExp]
                let isImperial = patientRow[Patient.isImperialExp]
                print("Loaded patient record")
                return Patient(firstName: firstName, lastName: lastName, patientHeight: patientHeight, patientWeight: patientWeight, dateOfBirth: dateOfBirth, gender: gender, isImperial: isImperial)
            } else {
                print("No patient record found")
                return defaultPatient
            }
        } catch {
            print("Error loading patient: \(error)")
            return defaultPatient
        }
    }
}

