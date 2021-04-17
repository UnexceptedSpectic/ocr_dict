//
//  UserCollection.swift
//  OCR Dictionary
//
//  Created by Philip on 3/29/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import Foundation

struct FirestoreUserCollection {
    
    let name: String
    let entries: [CollectionEntry]
}

struct CollectionEntry {
    
    let word: String
    let dateAdded: String
    let starredCellIndexes: [Int]
}
