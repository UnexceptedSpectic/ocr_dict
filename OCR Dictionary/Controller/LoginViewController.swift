//
//  LoginViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 8/24/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var nav: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        passwordField.delegate = self
        // Ensure back button is enabled
        self.nav.hidesBackButton = false
    }
    
    @IBAction func didTapLogInButton(_ sender: UIButton) {
        self.view.endEditing(true)
        // Disable back button
        self.nav.hidesBackButton = true
        // Authenticate User
        checkAndAuth()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField {
            passwordField.becomeFirstResponder()
        } else {
            textField.endEditing(true)
            // Authenticate user
            checkAndAuth()
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        // Close keyboard on touch outside of it
        self.view.endEditing(true)
    }
    
    func checkAndAuth() {
        if emailField.text != "" && passwordField.text != "" {
            messageLabel.text = "Logging in..."
            // Authenticate user
            Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!) { (authResult, error) in
                if let e = error {
                    self.messageLabel.text = e.localizedDescription
                } else {
                    self.performSegue(withIdentifier: "LoginToApp", sender: self)
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
