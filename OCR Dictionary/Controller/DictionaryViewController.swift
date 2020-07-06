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
                
                // Configure wordType cells. Subtract one for the storyboard prototype cell
                let wordType = result.lexicalEntries![indexPath.row - 1]
                
                self.setCellLabelText(for: cell.categoryLabel, as: wordType.lexicalCategory!.id)
                
                // Each lexical category has a single entry and a single sense, so can force unwrap
                let sense = wordType.entries![0].senses![0]
                
                let definitionText = sense.definitions![0]
                
                var examplesText = ""
                
                if let examples = sense.examples {
                    
                    for (ind, example) in examples.enumerated() {
                        
                        if let notes = example.notes {
                            
                            examplesText += "[" + notes[0].text! + "]: " + example.text!
                            
                        } else {
                            
                            examplesText += example.text!
                            
                        }
                        if ind != examples.count - 1 {
                            examplesText += " | "
                        }
                    }
                }
                
                self.setCellLabelText(for: cell.definitionLabel, as: definitionText + ": " + examplesText)
                
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
