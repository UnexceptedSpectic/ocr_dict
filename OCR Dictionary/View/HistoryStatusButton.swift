//
//  HistoryStatusButton.swift
//  OCR Dictionary
//
//  Created by Philip on 8/29/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import UIKit

class HistoryStatusButton: UIButton {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == self && self.status! == SavedStatus.NOT_SAVED {
            return nil
        }
        return hitView
    }
    
    enum SavedStatus {
        case SAVED
        case NOT_SAVED
    }
    
    var status: SavedStatus?

}
