//
//  AccountViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 9/12/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit
import Firebase

class AccountViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func didTapSignOut(_ sender: UIBarButtonItem) {
        
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: false)
        } catch let error as NSError {
            print("Error signing out: \(error).")
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