//
//  RegisterViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 8/24/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit
import Firebase

class RegisterViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var nav: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        passwordField.delegate = self
        // Ensure back button is enabled
        self.nav.hidesBackButton = false
    }
    
    @IBAction func didTapRegisterButton(_ sender: UIButton) {
        self.view.endEditing(true)
        // Disable back button
        self.nav.hidesBackButton = true
        // Register user
        checkAndRegister()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField {
            passwordField.becomeFirstResponder()
        } else {
            textField.endEditing(true)
            // Register user
            checkAndRegister()
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesBegan(touches, with: event)
        
        self.view.endEditing(true)
    }
    
    func checkAndRegister() {
       
        if emailField.text != "" && passwordField.text != "" {
            messageLabel.text = "Registering..."
            // Register user
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { authResult, error in
                if let e = error {
                    self.messageLabel.text = e.localizedDescription
                } else {
                    
                    self.performSegue(withIdentifier: "RegisterToLibrary", sender: self)
                }
            }
        } else {
            // Tell the user to enter text into both fields
            messageLabel.text = "Please enter your account email and password."
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
