//
//  Cell.swift
//  OCR Dictionary
//
//  Created by Philip on 8/22/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import Foundation

struct Cell {
    let type: String
    let resultIndex: Int
    let lexicalIndex: Int?
    let senseIndex: Int?
    let subsenseIndex: Int?
    let text: [NSAttributedString]?
    var saved: Bool = false
}
