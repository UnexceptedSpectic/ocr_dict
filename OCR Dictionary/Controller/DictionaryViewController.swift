//
//  DictionaryViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 6/27/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit

class DictionaryViewController: UIViewController {
    
    @IBOutlet weak var dicitonaryTableView: UITableView!
    @IBOutlet weak var queryWordLabel: UILabel!
    
    var queryWord: String?
    var wordData: WordData?
    var wordDataGetterGroup: DispatchGroup?
    var definitionTableGroup = DispatchGroup()
    var cells: [Cell]?
    
    // Define text attribute presets
    let heading1Attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24), NSAttributedString.Key.foregroundColor: UIColor.label]
    let italicSecondaryHeading1Attributes = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
    let heading2Attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.label]
    let primary14Attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label]
    let secondary14Attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
    let italicSecondary14Attributes = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
    let italicTertiary14Attributes = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.tertiaryLabel]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch definition data
        var dictionaryManager = DictionaryManager()
        dictionaryManager.delegate = self
        
        wordDataGetterGroup = DispatchGroup()
        wordDataGetterGroup!.enter()
        
        DispatchQueue.main.async {
            dictionaryManager.getDefinitionData(word: self.queryWord!)
        }
        
        // Set query word to label at top of view
        self.queryWordLabel.text = queryWord
        
        // Configure the result table view
        dicitonaryTableView.allowsSelection = false
        
        // Start loading table after definition data is obtained (and all other dispatch group tasks are completed)
        DispatchQueue.main.async {
            
            self.wordDataGetterGroup!.notify(queue: .main) {
                
                self.dicitonaryTableView.delegate = self
                self.dicitonaryTableView.dataSource = self
                self.dicitonaryTableView.reloadData()
                
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    func getCellStructs(wordDataResults: [Result]?) -> [Cell]? {
        // Create a list of cell objects that describe cell type and a cell content's location in the Oxford API data structure
        var cells: [Cell] = []
        
        if let results = wordDataResults {
            
            for (resInd, result) in results.enumerated() {
                
                cells.append(Cell(type: K.tables.dictionary.cell.type.name, resultIndex: resInd, lexicalIndex: nil, senseIndex: nil, subsenseIndex: nil,
                                   text: [NSAttributedString(string: result.word!,
                                                             attributes: heading1Attributes),
                                          NSAttributedString(string: "| " + result.lexicalEntries![0].entries![0].pronunciations!.last!.phoneticSpelling! + " |",
                                                             attributes: italicSecondaryHeading1Attributes)]))
                
                for (lexInd, entry) in result.lexicalEntries!.enumerated() {
                    cells.append(Cell(type: K.tables.dictionary.cell.type.category, resultIndex: resInd, lexicalIndex: lexInd, senseIndex: nil, subsenseIndex: nil, text: [NSAttributedString(string: entry.lexicalCategory!.id!, attributes: heading2Attributes)]))
                    
                    if let primaryDefinitions = entry.entries![0].senses {
                        for (primDefInd, primaryDef) in primaryDefinitions.enumerated() {
                            
                            // Configure primary sense/definition and examples text
                            var definitionText = NSMutableAttributedString(string: "")
                            
                            if let definitions = primaryDef.definitions {
                                definitionText = NSMutableAttributedString(string: definitions[0], attributes: primary14Attributes)
                            }
                            
                            let examplesText = NSMutableAttributedString(string: "")
                            
                            // Add examples for the defined word
                            if let examples = primaryDef.examples {
                                
                                examplesText.append(NSAttributedString(string: ": "))
                                
                                for (ind, example) in examples.enumerated() {
                                    
                                    // Add note text
                                    if let notes = example.notes {
                                        
                                        examplesText.append(NSAttributedString(string: "[\(notes[0].text!)]: ", attributes: italicTertiary14Attributes))
                                        
                                    }
                                    
                                    // Add example text
                                    examplesText.append(NSAttributedString(string: example.text!, attributes: italicSecondary14Attributes))
                                    
                                    if ind != examples.count - 1 {
                                        
                                        examplesText.append(NSAttributedString(string: " | "))
                                        
                                    } else {
                                        
                                        examplesText.append(NSAttributedString(string: "."))
                                        
                                    }
                                }
                            }
                            
                            definitionText.append(examplesText)
                            
                            cells.append(Cell(type: K.tables.dictionary.cell.type.primaryDefinition, resultIndex: resInd, lexicalIndex: lexInd, senseIndex: primDefInd, subsenseIndex: nil, text: [definitionText]))
                            
                            // Add subsense definition and example text to primary data text
                            if let subsenses = primaryDef.subsenses {
                                
                                for (subsenseInd, subsense) in subsenses.enumerated() {
                                    
                                    let subsensesText = NSMutableAttributedString(string: "")
                                    
                                    // Check for and attempt to save subsense definition. Continue only if one is found.
                                    var subsenseDefinition: NSAttributedString?
                                    if let definitions = subsense.definitions {
                                        
                                        subsenseDefinition = NSAttributedString(string: definitions[0], attributes: primary14Attributes)
                                        
                                    } else if let crossReferenceMarkers = subsense.crossReferenceMarkers {
                                        
                                        subsenseDefinition = NSAttributedString(string: crossReferenceMarkers[0], attributes: primary14Attributes)
                                        
                                    } else {
                                        
                                        // Skip iteration
                                        continue
                                    }
                                    
                                    // Add subsense note
                                    if let notes = subsense.notes {
                                        
                                        subsensesText.append(NSAttributedString(string: "[\(notes[0].text!)] ", attributes: italicTertiary14Attributes))
                                        
                                    }
                                    
                                    // Add subsense domain
                                    if let domains = subsense.domains {
                                        
                                        subsensesText.append(NSAttributedString(string: "\(domains[0].text!) ", attributes: italicTertiary14Attributes))
                                        
                                    }
                                    
                                    // Add subsense definition
                                    subsensesText.append(subsenseDefinition!)
                                    
                                    // Add subsense examples
                                    let examplesText = NSMutableAttributedString(string: "")
                                    
                                    if let examples = subsense.examples {
                                        
                                        examplesText.append(NSAttributedString(string: ": "))
                                        
                                        for (ind, example) in examples.enumerated() {
                                            
                                            examplesText.append(NSAttributedString(string: example.text!, attributes: italicSecondary14Attributes))
                                            
                                            if ind != examples.count - 1 {
                                                
                                                examplesText.append(NSAttributedString(string: " | "))
                                                
                                            } else {
                                                
                                                examplesText.append(NSAttributedString(string: "."))
                                                
                                            }
                                        }
                                        
                                        subsensesText.append(examplesText)
                                        
                                    }
                                    
                                    cells.append(Cell(type: K.tables.dictionary.cell.type.secondaryDefenition, resultIndex: resInd, lexicalIndex: lexInd, senseIndex: primDefInd, subsenseIndex: subsenseInd, text: [subsensesText]))
                                }
                            }
                        }
                    }
                    
                }
                
                if let etymologies = result.lexicalEntries![0].entries![0].etymologies {
                    
                    cells.append(Cell(type: K.tables.dictionary.cell.type.origin, resultIndex: resInd, lexicalIndex: nil, senseIndex: nil, subsenseIndex: nil, text: [NSAttributedString(string: etymologies[0])]))
                }
            }
            
        } else {
            
            // No results found for oxford api word query
            cells = [Cell(type: K.tables.dictionary.cell.type.noResult, resultIndex: 0, lexicalIndex: nil, senseIndex: nil, subsenseIndex: nil, text: [NSAttributedString(string: "No results found", attributes: heading1Attributes)])]
            
        }
        
        return cells
    }
    
}

// TODO: remove - no selection actions needed here
// Extensions for the dictionary table view
extension DictionaryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
}

extension DictionaryViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Return the total number of cells required
        self.cells = getCellStructs(wordDataResults: self.wordData?.results)
        return self.cells!.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellType = cells![indexPath.row].type
        let resultIndex = cells![indexPath.row].resultIndex
        let primDefInd = cells![indexPath.row].senseIndex
        let cellText = cells![indexPath.row].text
        
        var cell: UITableViewCell?
        
        switch(cellType) {
            
        case K.tables.dictionary.cell.type.name:
            // Create cell from storyboard prototype cell for word name/string
            cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.type.name, for: indexPath)
            // Set text
            let wordLabel = cell!.viewWithTag(1) as! UILabel
            let resultNumLabel = cell!.viewWithTag(2) as! UILabel
            let phoneticLabel = cell!.viewWithTag(3) as! UILabel
            wordLabel.attributedText = cellText![0]
            resultNumLabel.text = String(resultIndex + 1)
            phoneticLabel.attributedText = cellText![1]
            // Set name label width
            wordLabel.constraintWithIdentifier("wordLabelWidth")!.constant = wordLabel.intrinsicContentSize.width
            // Set result number label width
            resultNumLabel.constraintWithIdentifier("resultNumLabelWidth")!.constant = resultNumLabel.intrinsicContentSize.width
        case K.tables.dictionary.cell.type.category:
            // Create cell from storyboard prototype cell for word category
            cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.type.category, for: indexPath)
            // Set text
            let categoryLabel = cell!.viewWithTag(1) as! UILabel
            categoryLabel.attributedText = cellText![0]
        case K.tables.dictionary.cell.type.primaryDefinition:
            // Create cell from storyboard prototype cell for primary definition
            cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.type.primaryDefinition, for: indexPath)
            // Set text
            let primDefNumLabel = cell!.viewWithTag(1) as! UILabel
            let primDefLabel = cell!.viewWithTag(2) as! UILabel
            primDefNumLabel.attributedText = NSAttributedString(string:String(primDefInd! + 1), attributes: secondary14Attributes)
            primDefLabel.attributedText = cellText![0]
        case K.tables.dictionary.cell.type.secondaryDefenition:
            // Create cell from storyboard prototype cell for secondary/sub definition
            cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.type.secondaryDefenition, for: indexPath)
            // Set text
            let subDefLabel = cell!.viewWithTag(1) as! UILabel
            subDefLabel.attributedText = cellText![0]
        case K.tables.dictionary.cell.type.origin:
            // Create cell from storyboard prototype cell for word origin
            cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.type.origin, for: indexPath)
            // Set text
            let originLabel = cell!.viewWithTag(1) as! UILabel
            originLabel.attributedText = cellText![0]
        case K.tables.dictionary.cell.type.noResult:
            cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.type.name, for: indexPath)
            // Set text
            let msg = cell!.viewWithTag(1) as! UILabel
            msg.attributedText = cellText![0]
        default:
            print("Error: cellType not matched")
        }
        
        let containerView = cell!.contentView.subviews[0]
        if indexPath.row == 0 {
            // Round top corners of first cell. Acts on cell prototype, not its instance.
            containerView.layer.cornerRadius = 10
            containerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
        
        // Round bottom corners of last cell in each result. Acts on cell prototype, not its instance.
        if indexPath.row + 1 == cells!.count || cells![indexPath.row + 1].resultIndex == resultIndex + 1 {
            containerView.layer.cornerRadius = 10
            containerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        
        // Set result container top margins
        if indexPath.row == 0 {
            containerView.constraintWithIdentifier("resultContainerTopMargin")!.constant = 20
        } else if cells![indexPath.row - 1].resultIndex == resultIndex - 1 {
            containerView.constraintWithIdentifier("resultContainerTopMargin")!.constant = 10
        }
        
        // Set result container bottom margins
        if indexPath.row + 1 == cells!.count {
            containerView.superview!.constraintWithIdentifier("resultContainerBottomMargin")!.constant = 20
        } else if cells![indexPath.row + 1].resultIndex == resultIndex + 1 {
            containerView.superview!.constraintWithIdentifier("resultContainerBottomMargin")!.constant = 0
        }
        
        cell!.layoutIfNeeded()
        
        return cell!
        
    }
    
}

extension DictionaryViewController: WordDataDelegate {
    
    func didGetWordData(wordData: WordData) {
        self.wordData = wordData
        self.wordDataGetterGroup!.leave()
    }
    
}

extension UIView {
    /// Returns the first constraint with the given identifier, if available.
    ///
    /// - Parameter identifier: The constraint identifier.
    func constraintWithIdentifier(_ identifier: String) -> NSLayoutConstraint? {
        return self.constraints.first { $0.identifier == identifier }
    }
}
