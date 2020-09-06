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
    
    var cells: [Cell]?
    
    var heightOfAddedLabels: CGFloat = 0
    
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
        dicitonaryTableView.register(TableViewCell.nib(nibName: K.tables.dictionary.cell.nib.lexical), forCellReuseIdentifier: K.tables.dictionary.cell.type.lexical)
        dicitonaryTableView.showsVerticalScrollIndicator = false
        dicitonaryTableView.allowsSelection = false
        
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
    
}

// Extensions for the dictionary table view
extension DictionaryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
}

extension DictionaryViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                
        // Return the total number of cells required
        // Create a list of cell objects that describe cell type and a cell's index in its enclosing data structure
        if let results = self.wordData?.results {
            
            cells = [Cell(type: K.tables.dictionary.cell.type.name, resultIndex: 0, indexInContainer: nil)]
            
            for (resInd, result) in results.enumerated() {
                
                if resInd != 0 {
                    cells?.append(Cell(type: K.tables.dictionary.cell.type.name, resultIndex: 0, indexInContainer: nil))
                }
                for (lexInd, _) in result.lexicalEntries!.enumerated() {
                    cells?.append(Cell(type: K.tables.dictionary.cell.type.lexical, resultIndex: resInd, indexInContainer: lexInd))
                }
                cells?.append(Cell(type: K.tables.dictionary.cell.type.origin, resultIndex: 0, indexInContainer: nil))
                
            }
            
            return cells!.count
            
        } else {
            
            // No results found for oxford api word query
            cells = [Cell(type: K.tables.dictionary.cell.type.noResult, resultIndex: 0, indexInContainer: nil)]
            return 1
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellType = cells![indexPath.row].type
        let resultIndex = cells![indexPath.row].resultIndex
        let indexInContainer = cells![indexPath.row].indexInContainer
        
        if let results = self.wordData?.results {
        
            if cellType == K.tables.dictionary.cell.type.name {
                
                // Create cell from storyboard prototype cell for word being queried
                let cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.type.name, for: indexPath)
                
                // Set radius for top corners of word container
                let wordContainerView = cell.contentView.subviews[0]
                wordContainerView.layer.cornerRadius = 10
                wordContainerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
                
                // Access the appropriate result
                let result = results[resultIndex]
                // Set word and phonetics text
                self.setCellLabelText(for: wordContainerView.subviews[0] as! UILabel, as: result.word)
                
                // Update frame height. Autolayout doesn't seem to do so as elements change in height. May be an issue with how constraints are set up.
                cell.frame = self.updatedFrameHeight(for: cell.frame, addHeight: self.heightOfAddedLabels)
                return cell
                
            } else if cellType == K.tables.dictionary.cell.type.origin {
                
                // Create cell from storyboard prototype cell for word origin
                let cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.type.origin, for: indexPath)
                
                // Round bottom corners
                let originContainerView = cell.contentView.subviews[0]
                originContainerView.layer.cornerRadius = 10
                originContainerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                
                // Assume that the first lexical entry of a given result contains etymology info
                let entry = results[resultIndex].lexicalEntries![0].entries![0]
                
                // Get and assign etymology data
                if let etymologies = entry.etymologies {
                    
                    self.setCellLabelText(for: originContainerView.subviews.last as! UILabel, as: etymologies[0])
                    
                } else {
                    // Hide the contents of the origin cell
                    cell.isHidden = true
                    
                }
                
                // Update frame height. Autolayout doesn't seem to do so as elements change in height. May be an issue with how constraints are set up.
                cell.frame = self.updatedFrameHeight(for: cell.frame, addHeight: self.heightOfAddedLabels)
                return cell
                
            } else {
                
                // Create cell using xib template for wordType and definition: [note] example, ... content
                let cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.type.lexical, for: indexPath) as! TableViewCell
                    
                // Assume that only one result will ever be found
                let result = results[resultIndex]
                
                // Set word type e.g. adjective to work with. Subtract one for the first storyboard prototype cell
                let wordType = result.lexicalEntries![indexInContainer!]
                
                self.setCellLabelText(for: cell.categoryLabel, as: wordType.lexicalCategory!.id)
                
                // Define text attribute presets
                let italicSecondary14Attributes = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
                let italicTertiary14Attributes = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.tertiaryLabel]
                
                // Extract primary sense and subsense data
                let definitionsText = NSMutableAttributedString(string: "")
                
                // Only ever one entry per word type
                let entry = wordType.entries![0]
                
                for (ind, sense) in entry.senses!.enumerated() {
                    
                    // Configure primary sense/definition and examples text
                    let definitionNumber: String
                    if entry.senses!.count > 1 {
                        
                        definitionNumber = "\(String(ind + 1)). "
                        
                    } else {
                        
                        definitionNumber = ""
                        
                    }
                    
                    var definitionText = NSMutableAttributedString(string: "")
                    
                    if let definitions = sense.definitions {
                        definitionText = NSMutableAttributedString(string: "\(definitionNumber)\(definitions[0])")
                    }
                    
                    let examplesText = NSMutableAttributedString(string: "")
                    
                    // Add examples for the defined word
                    if let examples = sense.examples {
                        
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
                    
                    // Add subsense definition and example text to primary data text
                    if let subsenses = sense.subsenses {
                        
                        let subsensesText = NSMutableAttributedString(string: "")
                        
                        for subsense in subsenses {
                            
                            // Check for and attempt to save subsense definition. Continue only if one is found.
                            var subsenseDefinition: String?
                            if let definitions = subsense.definitions {
                                
                                subsenseDefinition = definitions[0]
                                
                            } else if let crossReferenceMarkers = subsense.crossReferenceMarkers {
                                
                                subsenseDefinition = crossReferenceMarkers[0]
                                
                            } else {
                                
                                // Skip iteration
                                continue
                                
                            }
                            
                            // Create a new, bulleted row
                            subsensesText.append(NSAttributedString(string: "\n\n\u{2022} "))
                            
                            // Add subsense note
                            if let notes = subsense.notes {
                                
                                subsensesText.append(NSAttributedString(string: "[\(notes[0].text!)] ", attributes: italicTertiary14Attributes))
                                
                            }
                            
                            // Add subsense domain
                            if let domains = subsense.domains {
                                
                                subsensesText.append(NSAttributedString(string: "\(domains[0].text!) ", attributes: italicTertiary14Attributes))
                                
                            }
                            
                            // Add subsense definition
                            subsensesText.append(NSAttributedString(string: subsenseDefinition!))
                            
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
                        }
                        
                        definitionText.append(subsensesText)
                        
                    }
                    
                    // Save text for the data of each primary sense and its subsenses
                    definitionsText.append(definitionText)
                    
                    if ind < entry.senses!.count {
                        
                        definitionsText.append(NSAttributedString(string: "\n\n"))
                        
                    }
                    
                }
                
                // Configure cell with definitions and examples text
                self.setCellLabelAttributeText(for: cell.definitionLabel, as: definitionsText)
                                               
               // Round bottom corners of cell if no word origin cell ahead
                let nextCellType = cells![indexPath.row + 1].type
               if entry.etymologies == nil && nextCellType == K.tables.dictionary.cell.type.origin {
                
                    let lastWordDataContainerView = cell.contentView.subviews[0]
                    lastWordDataContainerView.layer.cornerRadius = 10
                    lastWordDataContainerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                
                }
                
                
                // Update frame height. Autolayout doesn't seem to do so as elements change in height. May be an issue with how constraints are set up.
                cell.frame = self.updatedFrameHeight(for: cell.frame, addHeight: self.heightOfAddedLabels)
                return cell
            }
            
        } else {
            
             // Create a cell for when a word did not return any results
            let cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.type.name, for: indexPath)
            
            // Round all corners
            let wordContainerView = cell.contentView.subviews[0]
            wordContainerView.layer.cornerRadius = 10
            wordContainerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            
            // Give cell container bottom padding
            let contentBottomConstraint = cell.contentView.constraints.filter { $0.identifier == "wordLabelContentViewBottom"}
            let containerBottonConstraint = cell.contentView.subviews[0].constraints.filter { $0.identifier == "wordLabelContainerViewBottom"}
            contentBottomConstraint[0].constant = 20
            containerBottonConstraint[0].constant = 20
            cell.updateConstraints()
            
            // Set error message text
            let word = wordContainerView.subviews[0] as! UILabel
            self.setCellLabelText(for: word, as: "No results found")
            word.font = UIFont(name: K.brand.fonts.systemDefault, size: 14)
            
            // Update frame height. Autolayout doesn't seem to do so as elements change in height. May be an issue with how constraints are set up.
            cell.frame = self.updatedFrameHeight(for: cell.frame, addHeight: self.heightOfAddedLabels)
            return cell
            
        }
        
    }
    
    func setCellLabelText(for label: UILabel, as text: String?) {
        
        if let newText = text {
            
            label.text = newText
            self.heightOfAddedLabels += label.intrinsicContentSize.height
            
        }
        
    }
    
    func setCellLabelAttributeText(for label: UILabel, as text: NSMutableAttributedString) {
        
        label.attributedText = text
        self.heightOfAddedLabels += label.intrinsicContentSize.height
        
    }
    
    func updatedFrameHeight(for frame: CGRect, addHeight: CGFloat) -> CGRect {
        
        var updatedFrame = frame
        updatedFrame.size.height = addHeight
        return updatedFrame
        
    }
    
}

extension DictionaryViewController: WordDataDelegate {
    
    func didGetWordData(wordData: WordData) {
        self.wordData = wordData
        self.wordDataGetterGroup!.leave()
    }
    
}
