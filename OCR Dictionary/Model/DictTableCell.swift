//
//  DictTableCell.swift
//  OCR Dictionary
//
//  Created by Philip on 4/16/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

// Data structures holding the information pertaining to the table view cells shown in the DictionaryViewController

import Foundation

protocol DictTableCell {
    var indexLocation: [Int] { get }
}

struct WordPronounciationCell: DictTableCell {
    let indexLocation: [Int]
    let wordText: NSAttributedString
    let phoneticText: NSAttributedString?
}

struct LexicalCategoryCell: DictTableCell {
    let indexLocation: [Int]
    let categoryText: NSAttributedString
}

class DefinitionCell: DictTableCell {
    let type: String
    let indexLocation: [Int]
    var saved: Bool
    let definition: NSAttributedString
    let examples: NSAttributedString?
    
    init(type: String, indexLocation: [Int], saved: Bool, definition: NSAttributedString, examples: NSAttributedString?) {
        self.type = type
        self.indexLocation = indexLocation
        self.saved = saved
        self.definition = definition
        self.examples = examples
    }
}

struct OriginCell: DictTableCell {
    let indexLocation: [Int]
    let etymology: NSAttributedString
}

struct NoResultCell: DictTableCell {
    let indexLocation = [0]
}
