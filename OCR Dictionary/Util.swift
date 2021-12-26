//
//  Util.swift
//  OCR Dictionary
//
//  Created by Philip on 3/30/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import Foundation
import DictionaryCoding
import UIKit
import Firebase

func parseJSON<T: Decodable>(jsonData: Data, dataModel: T.Type) -> T? {
    
    let decoder = JSONDecoder()
    do {
        
        let decodedData = try decoder.decode(dataModel.self, from: jsonData)
        return decodedData
        
    } catch {
        
        print(print("Error: decoding json data failed: ", error))
        return nil
        
    }
    
}

func parseDict<T: Decodable>(dictData: Dictionary<String, Any>, dataModel: T.Type) -> T? {
    
    let decoder = DictionaryDecoder()
    do {
        let decodedData = try decoder.decode(dataModel.self, from: dictData)
        return decodedData
    } catch {
        
        print("Error: decoding dictionary data failed: ", error)
        return nil
    }
    
}

func structToDict<T: Encodable>(structInstance: T) -> Dictionary<String, Any>? {
    
    let encoder = DictionaryEncoder()
    do {
        let encodedDict = try encoder.encode(structInstance) as [String: Any]
        return encodedDict
    } catch {
        
        print("Error: encoding struct data to dictionary failed: ", error)
        return nil
    }
}

func uppercaseFirstCharacter(str: String) -> String {
    let strArray = str.map { String($0) }
    return strArray[0].uppercased() + strArray[1...(strArray.count - 1)].joined(separator: "")
}

func getDatetimeString() -> String {
    let df = DateFormatter()
    // E.g. 1/1/2020 2:05 PM
    df.dateFormat = "M/d/yyyy h:mm a"
    return df.string(from: Date())
}

func getDateString(dateTime: String) -> String {
    // Returns either 'Today' or the date as e.g. 'Wednesday, January 1'
    let df = DateFormatter()
    df.dateFormat = "M/d/yyyy h:mm a"
    let date = df.date(from: dateTime)!
    if Calendar.current.isDateInToday(date) {
        return "Today"
    } else {
        df.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")
    }
    return df.string(from: date)
}

func getDate(dateString: String) -> Date {
    let df = DateFormatter()
    df.dateFormat = "EEEE, MMMM d"
    return df.date(from: dateString)!
}

func getTime(dateTime: String) -> String {
    let df = DateFormatter()
    df.dateFormat = "M/d/yyyy h:mm a"
    let date = df.date(from: dateTime)!
    df.setLocalizedDateFormatFromTemplate("h:mm a")
    return df.string(from: date)
}

func getDateOrTime(dateTime: String) -> String {
    // Returns the date if not today, else returns the time
    let df = DateFormatter()
    df.dateFormat = "M/d/yyyy h:mm a"
    let date = df.date(from: dateTime)!
    if Calendar.current.isDateInToday(date) {
        df.setLocalizedDateFormatFromTemplate("h:mm a")
    } else {
        df.setLocalizedDateFormatFromTemplate("d/M/yyyy")
    }
    return df.string(from: date)
}

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
    var strip: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

extension UIView {
    func firstConstraintWithIdentifier(_ identifier: String) -> NSLayoutConstraint? {
        let constraint = self.constraints.first { $0.identifier == identifier }
        if constraint != nil  {
            return constraint
        } else {
            for subview in self.subviews {
                if let constraint = subview.firstConstraintWithIdentifier(identifier) {
                    return constraint
                }
            }
        }
        return nil
    }
}

extension UIViewController {
    func presentingViewController(forModalController modalController: UIViewController) -> UIViewController {
        // Return the view that presented the input modal view controller
        let navControllers = (modalController.presentingViewController as! UINavigationController).viewControllers
        return navControllers[navControllers.count - 1]
    }
}

func signOutAndGoHome(caller: UIViewController) {
    do {
        try Auth.auth().signOut()
        caller.view.window?.rootViewController?.dismiss(animated: true, completion: nil)

    } catch let error as NSError {
        print("Error signing out: \(error).")
    }
}
