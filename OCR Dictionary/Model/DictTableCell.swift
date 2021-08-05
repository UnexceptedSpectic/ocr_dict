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
    // [resInd, lexInd?, primDefInd?, subsenseInd?]
    // Represents that cell type's occurance number
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

struct DictTableCellFactory {
    static func createCellStructs(wordDataResults: [Result]?) -> [DictTableCell] {
        // Create a list of cell objects that describe cell type and a cell content's location in the Oxford API data structure
        
        var cells: [DictTableCell] = []
        
        if let results = wordDataResults {
            
            for (resInd, result) in results.enumerated() {
                
                var phoneticSpelling: String = ""
                if let pronunciations = result.lexicalEntries![0].entries![0].pronunciations {
                    phoneticSpelling = pronunciations.last!.phoneticSpelling!
                }
                
                cells.append(WordPronounciationCell(
                    indexLocation: [resInd],
                    wordText: NSAttributedString(
                        string: result.word!,
                        attributes: K.stringAttributes.heading1),
                    phoneticText: NSAttributedString(
                        string:  "| \(phoneticSpelling) |",
                        attributes: K.stringAttributes.italicSecondaryHeading1)
                )
                )
                
                for (lexInd, entry) in result.lexicalEntries!.enumerated() {
                    
                    cells.append(LexicalCategoryCell(
                        indexLocation: [resInd, lexInd],
                        categoryText: NSAttributedString(
                            string: entry.lexicalCategory!.id!,
                            attributes: K.stringAttributes.heading2)
                    )
                    )
                    
                    // Configure primary sense/definition and examples text
                    if let primaryDefinitions = entry.entries![0].senses {
                        for (primDefInd, primaryDef) in primaryDefinitions.enumerated() {
                            
                            if let defStruct = getDefinitionStruct(definitionData: primaryDef, indexLocation: [resInd, lexInd, primDefInd], type: K.dictionaries.oxford.definition.type.primary) {
                                cells.append(defStruct)
                            }
                            
                            // Configure subsense/definition and examples text
                            if let subsenses = primaryDef.subsenses {
                                
                                for (subsenseInd, subsense) in subsenses.enumerated() {
                                    
                                    if let defStruct = getDefinitionStruct(definitionData: subsense, indexLocation: [resInd, lexInd, primDefInd, subsenseInd], type: K.dictionaries.oxford.definition.type.secondary) {
                                        cells.append(defStruct)
                                    }
                                }
                            }
                        }
                    }
                    
                }
                
                if let etymologies = result.lexicalEntries![0].entries![0].etymologies {
                    
                    cells.append(OriginCell(
                                    indexLocation: [resInd],
                                    etymology: NSAttributedString(
                                        string: etymologies[0],
                                        attributes: K.stringAttributes.primary14)))
                }
            }
            
        } else {
            
            // No results found for oxford api word query
            cells = [NoResultCell()]
            
        }
        
        return cells
    }
    
    private static func getDefinitionStruct(definitionData: Definition, indexLocation: [Int], type: String) -> DefinitionCell? {
        
        // Build definition string
        let definitionText = NSMutableAttributedString(string: "")
        
        // Add domain text
        if let domains = definitionData.domains {
            definitionText.append(NSAttributedString(
                                    string: "\(domains[0].text) ",
                                    attributes: K.stringAttributes.italicTertiary14))
        }
        
        // Add note text
        if let notes = definitionData.notes {
            
            let noteText = getNoteText(notes: notes)
            definitionText.append(noteText)
        }
        
        // Add register text
        if let registerText = getRegisterText(definitionData: definitionData) {
            definitionText.append(registerText)
        }
        
        // Add definition/reference text
        let defText: String
        if let definitions = definitionData.definitions {
            defText = definitions[0]
        } else if let crossReferenceMarkers = definitionData.crossReferenceMarkers {
            defText = crossReferenceMarkers[0]
        } else {
            // Skip saving subsense
            return nil
        }
        definitionText.append(NSAttributedString(
                                string: defText,
                                attributes: K.stringAttributes.primary14))
        
        // Add definition examples string
        let examplesText = NSMutableAttributedString(string: "")
        if let examples = definitionData.examples {
            
            examplesText.append(NSAttributedString(
                                    string: ": ",
                                    attributes: K.stringAttributes.primary14))
            
            for (ind, example) in examples.enumerated() {
                
                // Add note text
                if let notes = example.notes {
                    
                    let noteText = getNoteText(notes: notes)
                    examplesText.append(noteText)
                }
                
                // Add example text
                examplesText.append(NSAttributedString(
                                        string: example.text!,
                                        attributes: K.stringAttributes.italicSecondary14))
                
                // Separate/punctuate examples
                let separatorText: String
                if ind != examples.count - 1 {
                    separatorText = " | "
                } else {
                    separatorText = "."
                }
                examplesText.append(NSAttributedString(
                                        string: separatorText,
                                        attributes: K.stringAttributes.primary14))
            }
        }
        
        return DefinitionCell(
            type: type,
            indexLocation: indexLocation,
            saved: false,
            definition: definitionText,
            examples: examplesText)
        
    }
    
    private static func getNoteText(notes: [Note]) -> NSAttributedString {
        let note = notes[0]
        let noteText = NSMutableAttributedString(string: "")
        if note.type == "wordFormNote" {
            noteText.append(NSAttributedString(string: "(", attributes: K.stringAttributes.primary14))
            noteText.append(NSAttributedString(string: note.text.trimmingCharacters(in: ["\""]), attributes: K.stringAttributes.boldPrimary14))
            noteText.append(NSAttributedString(string: ") ", attributes: K.stringAttributes.primary14))
        } else if note.type == "grammaticalNote" {
            noteText.append(NSAttributedString(string: "[\(note.text)] ", attributes: K.stringAttributes.italicTertiary14))
        } else {
            noteText.append(NSAttributedString(string: "[\(note.text)] ", attributes: K.stringAttributes.italicTertiary14))
            print("New definition note type found: \(note.type)")
        }
        return noteText
    }
    
    private static func getRegisterText(definitionData: Definition) -> NSAttributedString? {
        if let registers = definitionData.registers {
            let registerText: String
            if (definitionData.domains != nil || definitionData.notes != nil) {
                registerText = registers[0].text.lowercased()
            } else {
                registerText = uppercaseFirstCharacter(str: registers[0].text)
            }
            return NSAttributedString(string: "\(registerText) ", attributes: K.stringAttributes.italicTertiary14)
        } else {
            return nil
        }
    }
}
