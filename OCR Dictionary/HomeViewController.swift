//
//  ViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 5/29/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var defineButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func didTapCaptureButton(_ sender: UIButton) {
        performSegue(withIdentifier: "SnapperViewController", sender: self)
    }
    
}

