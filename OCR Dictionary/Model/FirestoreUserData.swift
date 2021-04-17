//
//  FirestoreUserData.swift
//  OCR Dictionary
//
//  Created by Philip on 4/7/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import Foundation

struct FirestoreUserData: Decodable, Encodable {
    
    let collections: [Collection]
}

struct Collection: Decodable, Encodable {
    
    let name: String
    let dateCreated: String
    let dateModified: String
    let words: [Word]
}

struct Word: Decodable, Encodable {
    
    let word: String
    let dateAdded: String
    let dateModified: String
    let starredCellIndexes: [Int]
}
