//
//  CollectionViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 9/19/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit

class CollectionViewController: UIViewController {
    
    @IBOutlet weak var collectionTable: UITableView!
    
    var firestoreManager: FirestoreManager?
    var userData: FirestoreUserData?
    var wordsData: [OxfordWordData?]?
    var collectionIndex: Int?
    var wordsDataGetterGroup: DispatchGroup?
    var hiddenCollectionTableSections = Set<Int>()
    var wordsCells: [[DictTableCell]]?
    var wordsGroupedCells: [[[DictTableCell]]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchDataLoadTable()
        
    }
    
    // Fetch word data and update collection table with it
    func fetchDataLoadTable() {
        
        // Configure handling of firestore methods
        self.firestoreManager = FirestoreManager()
        self.firestoreManager!.wordsDataDelegate = self
        
        // Fetch data on background thread
        self.wordsDataGetterGroup = DispatchGroup()
        self.wordsDataGetterGroup!.enter()
        
        DispatchQueue.main.async {
            // Fetch data for user's saved words, from firestore
            print("Fetching words data for collection view")
            self.firestoreManager!.getWordsData(for: self.userData!.collections[self.collectionIndex!].words)
        }
        
        // Load table after user data is obtained
        DispatchQueue.main.async {
            
            self.wordsDataGetterGroup!.notify(queue: .main) {
                
                self.collectionTable.delegate = self
                self.collectionTable.dataSource = self
                self.collectionTable.sectionHeaderHeight = UITableView.automaticDimension
                self.collectionTable.estimatedSectionHeaderHeight = 100
                print("Reloading table")
                self.collectionTable.reloadData()
                
            }
        }
    }
    
    @objc func toggleSectionDetails(_ sender: UIButton) {
        let section = sender.tag
        let sectionIndexPaths = self.wordsGroupedCells![section].enumerated()
            .map({ IndexPath(row: $0.offset, section: section) })
        // Add/remove section rows from view
        if self.hiddenCollectionTableSections.contains(section) {
            self.hiddenCollectionTableSections.remove(section)
            self.collectionTable.insertRows(at: sectionIndexPaths,
                                            with: .fade)
        } else {
            self.hiddenCollectionTableSections.insert(section)
            self.collectionTable.deleteRows(at: sectionIndexPaths,
                                            with: .fade)
        }
    }
    
    func getStarredCellIndexes(for word: String) -> [Int]? {
        // Return the starred cell indexes for a word, if it exists in the current collection
        if let wordData = self.userData!.collections[self.collectionIndex!].words.filter({ $0.word == word }).first {
            return wordData.starredCellIndexes
        } else {
            return nil
        }
    }
    
    func getDefaultDefinitionCellIndex(userWordData: Word) -> Int {
        if let ddci = userWordData.defaultDefinitionCellIndex {
            return ddci
        } else {
            // Use the first definition cell, which occurs after the first wordPronounciationCell and categoryCell cells
            return 2
        }
    }
}

extension CollectionViewController: FirestoreWordsDataDelegate {
    
    func didGetWordsData(wordsData: [OxfordWordData?]) {
        print("Setting words data")
        self.wordsData = wordsData
        // Convert oxford word data to cell structs
        self.wordsCells = []
        for word in wordsData {
            if let word = word {
                self.wordsCells!.append(DictTableCellFactory.createCellStructs(wordDataResults: word.results))
            }
        }
        // Group cell structs in lists of lexicalCategory and any number of definition cells
        var wordsGroupedCells: [[[DictTableCell]]] = []
        for (wordInd, word) in self.wordsCells!.enumerated() {
            var wordGroup: [[DictTableCell]] = []
            var cellGroup: [DictTableCell] = []
            let defaultDefinitionCellIndex = getDefaultDefinitionCellIndex(userWordData: self.userData!.collections[self.collectionIndex!].words[wordInd])
            let starredCellIndexes = getStarredCellIndexes(for: (word[0] as! WordPronounciationCell).wordText.string)!
            for (cellInd, cell) in word.enumerated() {
                if (cell is LexicalCategoryCell) {
                    cellGroup = []
                    cellGroup.append(cell as! LexicalCategoryCell)
                } else if (cell is DefinitionCell) {
                    // Omit default/primary favorite cell, which is included in section header
                    if (starredCellIndexes.contains(cellInd) && cellInd != defaultDefinitionCellIndex) {
                        cellGroup.append(cell as! DefinitionCell)
                    }
                }
                // Group must have at least one DefinitionCell
                if (cellGroup.filter({ $0 is DefinitionCell }).count > 0 ) {
                    wordGroup.append(cellGroup)
                    cellGroup.removeLast()
                }
            }
            wordsGroupedCells.append(wordGroup)
        }
        self.wordsGroupedCells = wordsGroupedCells
        self.hiddenCollectionTableSections = Set(0...wordsGroupedCells.count)
        self.wordsDataGetterGroup!.leave()
    }
    
}

extension CollectionViewController: UITableViewDataSource, UITableViewDelegate {
    
    // Required delegate method. Create a section for each word
    func numberOfSections(in tableView: UITableView) -> Int {
        if let userData = self.userData {
            return userData.collections[self.collectionIndex!].words.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let wordsGroupedCells = self.wordsGroupedCells {
            if self.hiddenCollectionTableSections.contains(section) {
                return 0
            } else {
                return wordsGroupedCells[section].count
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let templateCell = self.collectionTable.dequeueReusableCell(withIdentifier: K.tables.collection.cell.nib.primaryFavorite)!
        let wordLabel = templateCell.viewWithTag(1) as! UILabel
        let modDateLabel = templateCell.viewWithTag(2) as! UILabel
        let mainDefinitionLabel = templateCell.viewWithTag(3) as! UILabel
        let userWordData = userData!.collections[self.collectionIndex!].words[section]
        wordLabel.text = userWordData.word
        modDateLabel.text = getDateOrTime(dateTime: userWordData.dateModified)
        let defaultDefinitionCellIndex = getDefaultDefinitionCellIndex(userWordData: userWordData)
        if let wordsCells = self.wordsCells {
            let definitionCell = wordsCells[section][defaultDefinitionCellIndex] as! DefinitionCell
            mainDefinitionLabel.text = definitionCell.definition.string
        }
        let sectionButton = templateCell.contentView.viewWithTag(4) as! UIButton
        sectionButton.tag = section
        sectionButton
            .addTarget(self, action: #selector(self.toggleSectionDetails(_:)), for: .touchUpInside)
        return templateCell.contentView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.collectionTable.dequeueReusableCell(withIdentifier: K.tables.collection.cell.nib.secondaryFavorite)!
        let definitionLabel = cell.viewWithTag(2) as! UILabel
        
        if let wordsGroupedCells = self.wordsGroupedCells {
            let cellGroup = wordsGroupedCells[indexPath.section][indexPath.row]
            let categoryAndDefinition = NSMutableAttributedString()
            categoryAndDefinition.append((cellGroup[0] as! LexicalCategoryCell).categoryText)
            categoryAndDefinition.append(NSAttributedString(string: " "))
            categoryAndDefinition.append((cellGroup[1] as! DefinitionCell).definition)
            definitionLabel.attributedText = categoryAndDefinition
        } else {
            definitionLabel.text = "NA"
        }
        
        return cell
    }
    
}
