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
    
    // Track by how much a a dict table cell needs to grow in response added text
    var heightOfAddedLabels: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set query word to label at top of view
        self.queryWordLabel.text = queryWord
        
        // Configure the result table view
        dicitonaryTableView.register(TableViewCell.nib(nibName: TableViewCell.dictID), forCellReuseIdentifier: TableViewCell.dictID)
        dicitonaryTableView.delegate = self
        dicitonaryTableView.dataSource = self
        dicitonaryTableView.showsVerticalScrollIndicator = false
        
        var dictionaryManager = DictionaryManager()
        dictionaryManager.delegate = self
        
        wordDataGetterGroup = DispatchGroup()
        wordDataGetterGroup!.enter()
        
        DispatchQueue.main.async {
            dictionaryManager.getDefinitionData(word: self.queryWord!)
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
        
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.dictID, for: indexPath) as! TableViewCell
        // Asynchronously wait for asynchronous getting of word data to complete prior to population UI elements
        DispatchQueue.main.async {
            
            self.wordDataGetterGroup!.notify(queue: .main) {
                
                // Update cell labels with word data text
                self.setCellLabelText(for: cell.wordLabel, as: self.wordData?.results?[0].id)
                self.setCellLabelText(for: cell.categoryLabel, as: self.wordData?.results?[0].lexicalEntries?[0].lexicalCategory?.id)
                self.setCellLabelText(for: cell.definitionLabel, as: self.wordData?.results?[0].lexicalEntries?[0].entries?[0].senses?[0].definitions?[0])
               
                // Update frame height. Autolayout doesn't do so automatically?
                cell.frame = self.updatedFrameHeight(for: cell.frame, addHeight: self.heightOfAddedLabels)
                // Show cell. Hidden to hide changing view as elements update
                cell.isHidden = false
            
            }
        }
        return cell
        
    }
    
    func setCellLabelText(for label: UILabel, as text: String?) {
        
        if let newText = text {
            
            label.text = newText
            self.heightOfAddedLabels += label.intrinsicContentSize.height
            
        }
        
    }
    
    func updatedFrameHeight(for frame: CGRect, addHeight: CGFloat) -> CGRect {
        
        var updatedFrame = frame
        updatedFrame.size.height += addHeight
        return updatedFrame
        
    }
    
}

extension DictionaryViewController: WordDataDelegate {
    
    func didGetWordData(wordData: WordData) {
        self.wordData = wordData
        self.wordDataGetterGroup!.leave()
    }
    
}
