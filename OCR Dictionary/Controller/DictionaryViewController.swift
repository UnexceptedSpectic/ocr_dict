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
        dicitonaryTableView.register(TableViewCell.nib(nibName: TableViewCell.dictID), forCellReuseIdentifier: TableViewCell.dictID)
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
        
        let numberOfNoneWordtypeCells = 1
        
        if let results = self.wordData!.results {
            return results[0].lexicalEntries!.count + numberOfNoneWordtypeCells
        } else {
            return numberOfNoneWordtypeCells
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            
            // Create cell from storyboard prototype cell for word being queried
            let cell = tableView.dequeueReusableCell(withIdentifier: "word", for: indexPath)
            
            // Set radius for top corners of word container
            let wordContainerView = cell.contentView.subviews[0]
            wordContainerView.layer.cornerRadius = 10
            wordContainerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            
            if let results = self.wordData?.results {
                
                // Assume that only one result will ever be found
                let result = results[0]
                // Set word and phonetics text
                self.setCellLabelText(for: wordContainerView.subviews[0] as! UILabel, as: result.id)
                
            } else {
                self.setCellLabelText(for: wordContainerView.subviews[0] as! UILabel, as: "N/A")
            }
            
            // Update frame height. Autolayout doesn't seem to do so as elements change in height. May be an issue with how constraints are set up.
            cell.frame = self.updatedFrameHeight(for: cell.frame, addHeight: self.heightOfAddedLabels)
            return cell
            
        }
            //        else if indexPath.row == dicitonaryTableView.numberOfRows(inSection: 0) - 1 {
            //
            //            // Create final cell
            //
            //        }
        else {
            
            // Create cell using xib template for wordType and definition: [note] example, ... content
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.dictID, for: indexPath) as! TableViewCell
            
            if let results = self.wordData?.results {
                
                // Assume that only one result will ever be found
                let result = results[0]
                
                // Set word type e.g. adjective to work with. Subtract one for the storyboard prototype cell
                let wordType = result.lexicalEntries![indexPath.row - 1]
                
                self.setCellLabelText(for: cell.categoryLabel, as: wordType.lexicalCategory!.id)
                
                // Define text attribute presets
                let italicSecondaryAttributes = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
                let italicTertiaryAttributes = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.tertiaryLabel]
                
                // Extract primary sense and subsense data
                let definitionsText = NSMutableAttributedString(string: "")
                
                let senses = wordType.entries![0].senses!
                
                for (ind, sense) in senses.enumerated() {
                    
                    // Configure primary sense/definition and examples text
                    let definitionNumber: String
                    if senses.count > 1 {
                        
                        definitionNumber = "\(String(ind + 1)). "
                        
                    } else {
                        
                        definitionNumber = ""
                        
                    }
                    
                    let definitionText = NSMutableAttributedString(string: "\(definitionNumber)\(sense.definitions![0])")
                    let examplesText = NSMutableAttributedString(string: "")
                    
                    // Add examples for the defined word
                    if let examples = sense.examples {
                        
                        examplesText.append(NSAttributedString(string: ": "))
                        
                        for (ind, example) in examples.enumerated() {
                            
                            // Add note text
                            if let notes = example.notes {
                                
                                examplesText.append(NSAttributedString(string: "[\(notes[0].text!)]: ", attributes: italicTertiaryAttributes))
                                
                            }
                            
                            // Add example text
                            examplesText.append(NSAttributedString(string: example.text!, attributes: italicSecondaryAttributes))
                            
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
                                
                                subsensesText.append(NSAttributedString(string: "[\(notes[0].text!)] ", attributes: italicTertiaryAttributes))
                                
                            }
                            
                            // Add subsense domain
                            if let domains = subsense.domains {
                                
                                subsensesText.append(NSAttributedString(string: "\(domains[0].text!) ", attributes: italicTertiaryAttributes))
                                
                            }
                            
                            // Add subsense definition
                            subsensesText.append(NSAttributedString(string: subsenseDefinition!))
                            
                            // Add subsense examples
                            let examplesText = NSMutableAttributedString(string: "")
                            
                            if let examples = subsense.examples {
                                
                                examplesText.append(NSAttributedString(string: ": "))
                                
                                for (ind, example) in examples.enumerated() {
                                    
                                    examplesText.append(NSAttributedString(string: example.text!, attributes: italicSecondaryAttributes))
                                    
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
                    
                    if ind < senses.count {
                        
                        definitionsText.append(NSAttributedString(string: "\n\n"))
                        
                    }
                    
                }
                                
                // Configure cell with definitions and examples text
                self.setCellLabelAttributeText(for: cell.definitionLabel, as: definitionsText)
                
            }
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
