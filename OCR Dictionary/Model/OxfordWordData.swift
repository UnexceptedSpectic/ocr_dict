//
//  WordData.swift
//  OCR Dictionary
//
//  Created by Philip on 7/1/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

// Data structures representing the oxford dictionary api response

import Foundation


struct OxfordWordData: Decodable, Encodable {
    
    let results: [Result]?
    
}

struct Result: Decodable, Encodable {
    
    let word: String?
    let lexicalEntries: [LexicalEntry]?
    
}

struct LexicalEntry: Decodable, Encodable {
    
    let entries: [Entry]?
    let derivatives: [Derivative]?
    let lexicalCategory: LexicalCategory?
    
}

struct Entry: Decodable, Encodable {
    
    let etymologies: [String]?
    let pronunciations: [Pronunciation]?
    let senses: [Sense]?
    
}
struct Derivative: Decodable, Encodable {
    
    let text: String?
    
}

struct Pronunciation: Decodable, Encodable {
    
    let dialects: [String]?
    let phoneticSpelling: String?
    let audioFile: String?
    
}

protocol Definition {
    
    var definitions: [String]? { get }
    var crossReferenceMarkers: [String]? { get }
    var domains: [Domain]? { get }
    var examples: [Example]? { get }
    var synonyms: [Synonym]? { get }
    var notes: [Note]? { get }
    var shortDefinitions: [String]? { get }
    var registers: [Register]? { get }
    
}

struct Sense: Decodable, Encodable, Definition {
    
    let definitions: [String]?
    let crossReferenceMarkers: [String]?
    let domains: [Domain]?
    let examples: [Example]?
    let synonyms: [Synonym]?
    let notes: [Note]?
    let shortDefinitions: [String]?
    let subsenses: [Subsense]?
    let registers: [Register]?
    
}

struct Subsense: Decodable, Encodable, Definition {

    let definitions: [String]?
    let crossReferenceMarkers: [String]?
    let domains: [Domain]?
    let examples: [Example]?
    let synonyms: [Synonym]?
    let notes: [Note]?
    let shortDefinitions: [String]?
    let registers: [Register]?
    
}

struct Example: Decodable, Encodable {
    
    let notes: [Note]?
    let text: String?
    
}

struct Note: Decodable, Encodable {
    
    let text: String
    let type: String
    
}

struct Domain: Decodable, Encodable {
    
    let text: String
    
}

struct Register: Decodable, Encodable {
    
    let id: String
    let text: String
    
}

struct Synonym: Decodable, Encodable {
    
    let text: String?
    
}

struct LexicalCategory: Decodable, Encodable {
    
    let id: String?
    
}
