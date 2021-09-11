//
//  FirestoreUserData.swift
//  OCR Dictionary
//
//  Created by Philip on 4/7/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import Foundation

struct FirestoreUserData: Decodable, Encodable {
    
    var collections: [Collection]
    var history: [WordLookup]
}

struct Collection: Decodable, Encodable {
    
    var name: String
    let dateCreated: String
    var dateModified: String
    var words: [Word]
}

struct Word: Decodable, Encodable {
    
    let word: String
    let dateAdded: String
    var dateModified: String
    var starredCellIndexes: [Int]
    var defaultDefinitionCellIndex: Int?
}

struct WordLookup: Decodable, Encodable {
    
    let word: String
    let date: String
}
