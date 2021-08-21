//
//  OxfordLemmasData.swift
//  OCR Dictionary
//
//  Created by Philip on 8/19/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import Foundation

struct OxfordLemmasData: Decodable, Encodable {
    
    let results: [LemmaResult]?
}

struct LemmaResult: Decodable, Encodable {
    
    let word: String?
    let lexicalEntries: [LemmaLexicalEntry]?
}

struct LemmaLexicalEntry: Decodable, Encodable {
    
    let inflectionOf: [Inflection]
    let lexicalCategory: LemmaLexicalCategory
}

struct Inflection: Decodable, Encodable {
    
    let text: String
}

struct LemmaLexicalCategory: Decodable, Encodable {
    
    let text: String
}
