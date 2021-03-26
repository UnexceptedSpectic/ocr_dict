//
//  dictStarButton.swift
//  OCR Dictionary
//
//  Created by Philip on 3/26/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import UIKit

class dictStarButton: UIButton {

    private var indexPath: IndexPath?
    
    public func getIndexPath() -> IndexPath? {
        return self.indexPath
    }
    
    public func setIndexPath(indexPath: IndexPath) {
        self.indexPath = indexPath
    }

}
