//
//  BaseTabBarController.swift
//  OCR Dictionary
//
//  Created by Philip on 12/25/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import UIKit

class BaseTabBarController: UITabBarController {

    // Set library page as default view on login
    @IBInspectable var defaultIndex: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedIndex = defaultIndex
    }

}
