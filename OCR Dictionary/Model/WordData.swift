//
//  WordData.swift
//  OCR Dictionary
//
//  Created by Philip on 7/1/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import Foundation


struct WordData: Decodable {
    
    let results: [Result]?
    
}

struct Result: Decodable {
    
    let id: String?
    let lexicalEntries: [LexicalEntry]?
    
}

struct LexicalEntry: Decodable {
    
    let entries: [Entry]?
    let derivatives: [Derivative]?
    let lexicalCategory: LexicalCategory?
    
}

struct Entry: Decodable {
    
    let etymologies: [String]?
    let pronunciations: [Pronunciation]?
    let senses: [Sense]?
    
}
struct Derivative: Decodable {
    
    let text: String?
    
}

struct Pronunciation: Decodable {
    
    let dialects: [String]?
    let phoneticSpelling: String?
    let audioFile: String?
    
}

struct Sense: Decodable {
    
    let definitions: [String]?
    let examples: [Example]?
    let shortDefinitions: [String]?
    let subsenses: [Subsense]?
    let synonyms: [Synonym]?
    
}

struct Example: Decodable {
    
    let text: String?
    
}

struct Subsense: Decodable {
    
    let definitions: [String]?
    let examples: [Example]?
    let shortDefinitions: [String]?
    
}

struct Synonym: Decodable {
    
    let text: String?
    
}

struct LexicalCategory: Decodable {
    
    let id: String?
    
}
