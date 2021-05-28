//
//  DictionaryViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 6/27/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit
import CoreHaptics
import AudioToolbox.AudioServices

class DictionaryViewController: UIViewController {
    
    @IBOutlet weak var dicitonaryTableView: UITableView!
    @IBOutlet weak var queryWordLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    
    var queryWord: String?
    var wordData: OxfordWordData?
    var wordDataGetterGroup: DispatchGroup?
    var definitionTableGroup = DispatchGroup()
    var cells: [DictTableCell]?
    var dbUserData: FirestoreUserData?
    var firestoreManager: FirestoreManager?
    
    // For managing definition star state
    var starHeldDown: Bool = false
    var defaultDefinitionIndex: Int?
    var defaultDefinitionIndexUpdatePending: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the result table view
        dicitonaryTableView.allowsSelection = false
        
        // Disable save button until local data diverges from db version
        saveButton.isEnabled = false
        
        // Set query word to label at top of view
        self.queryWordLabel.text = queryWord
        
        // Fetch word data from firestore, else oxford api, then reload table
        fetchWordDataReloadTable()
    }
    
    func fetchWordDataReloadTable() {
        // Logic for fetching word data. Always query firestore first

        self.firestoreManager = FirestoreManager()
        self.firestoreManager!.wordDataDelegate =  self
        self.firestoreManager!.userDataDelegate = self
        
        // Perform firestore/oxford dict word queries on background thread
        wordDataGetterGroup = DispatchGroup()
        wordDataGetterGroup!.enter()
        
        DispatchQueue.main.async {
            // Fetch word cells from firestore
            print("starting to get user word cells")
            self.firestoreManager!.getWordData(for: self.queryWord!)
        }
        
        // Start loading table after word and user? data is obtained (all dispatch group tasks are completed/leave() is called)
        DispatchQueue.main.async {
            
            self.wordDataGetterGroup!.notify(queue: .main) {
                                
                // Set up dict table view and reload view, now that data has been obtained
                self.dicitonaryTableView.delegate = self
                self.dicitonaryTableView.dataSource = self
                self.dicitonaryTableView.reloadData()
                
            }
        }
    }
    
    @IBAction func didTapSave(_ sender: UIButton) {
        // Show word saver
//        performSegue(withIdentifier: "DictToSaver", sender: self)
        let updatedUserData = self.firestoreManager?.saveUserData(
            add: queryWord!,
            to: "testCollection",
            usingTemplate: dbUserData,
            newStarredCellIndexes: getSavedCellIndexes(cells: self.cells!),
            newDefaultDefinitionIndex: self.defaultDefinitionIndex)
        self.dbUserData = updatedUserData
        self.saveButton.isEnabled = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "DictToSaver" {
         
            let saverVC = segue.destination as! WordSaverViewController
            saverVC.wordCells = self.cells
        }
    }
    
    @objc func didTapStar(_ sender: dictStarButton) {
        self.starHeldDown = true
        let starHoldStart = Date()
        DispatchQueue.global(qos: .userInitiated).async {
            // Super star a definition if star button is held for certain period of time
            let holdThreshold = 0.05
            while self.starHeldDown {
                // Compare star hold duration to threshold
                if ((Date().timeIntervalSinceReferenceDate - starHoldStart.timeIntervalSinceReferenceDate) > holdThreshold) {
                    // Toggle definition cell as default/not
                    self.defaultDefinitionIndexUpdatePending = true
                    // Haptic/vibrate feedback
                    if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
                        UISelectionFeedbackGenerator().selectionChanged()
                    } else {
                        AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate) {}
                    }
                    DispatchQueue.main.async {
                        // Refresh table view
                        self.dicitonaryTableView.setNeedsDisplay()
                    }
                    break
                }

                // Sleep for 0.001 seconds between star hold duration checks
                usleep(1000)
            }
        }
    }
    
    @objc func didReleaseStar(_ sender: dictStarButton) {
        
        // Required to terminate async function in didTapStar()
        self.starHeldDown = false
        
       // Toggle definition cell as starred/not
        let cellIndex = sender.getIndexPath()!.row
        let cell = self.cells![cellIndex] as! DefinitionCell
        
        if self.defaultDefinitionIndexUpdatePending {
        // Sufficient hold event
            // Unsave previous default definition cell
            if let previousDefaultDefinitionCellIndex = self.defaultDefinitionIndex {
                let previousDefaultDefinitionCell = self.cells![previousDefaultDefinitionCellIndex] as! DefinitionCell
                previousDefaultDefinitionCell.saved = false
                self.cells![previousDefaultDefinitionCellIndex] = previousDefaultDefinitionCell
            }
            // Save current cell
            cell.saved = true
            // Update index
            self.defaultDefinitionIndex = cellIndex
        } else {
        // Tap event
            if (cell.saved) {
                cell.saved = false
                if self.defaultDefinitionIndex == cellIndex {
                    self.defaultDefinitionIndex = nil
                }
            } else {
                cell.saved = true
            }
        }
        
        // Reset definition cell touch state
        self.defaultDefinitionIndexUpdatePending = false
        
        self.cells![cellIndex] = cell
                
        // Enable/disable save button
        setSaveButtonState()

        // Refresh table view
        self.dicitonaryTableView.reloadData()
        // TODO: bring up window with list of collections to save to. add option to create collection.
    }
    
    func setSaveButtonState() {
        // Enable/disable save button
        let localStarredCellIndexes = getSavedCellIndexes(cells: self.cells!)
        if let dbUserData = self.dbUserData {
            if let firstCollection = self.firestoreManager!.getWordInFirstCollection(for: self.queryWord!, in: dbUserData) {
                let dbStarredCellIndexes = firstCollection.starredCellIndexes
                let dbDefaultDefinitionIndex = firstCollection.defaultDefinitionIndex
                // Enable save button if local user data differs from that in the db
                if (localStarredCellIndexes != dbStarredCellIndexes || self.defaultDefinitionIndex != dbDefaultDefinitionIndex) {
                    self.saveButton.isEnabled = true
                } else {
                    self.saveButton.isEnabled = false
                }
            } else {
                // Enable save button when the word is not found in any user collection in the db
                if (!localStarredCellIndexes.isEmpty || self.defaultDefinitionIndex != nil) {
                    self.saveButton.isEnabled = true
                } else {
                    self.saveButton.isEnabled = false
                }
            }
        } else {
            // Enable save button when user data could not be obtained from the database/prior to it having been asynchronously fetched
            if (!localStarredCellIndexes.isEmpty || self.defaultDefinitionIndex != nil) {
                self.saveButton.isEnabled = true
            } else {
                self.saveButton.isEnabled = false
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
    
    func getSavedCellIndexes(cells: [DictTableCell]) -> [Int] {
        
        var savedCellIndexes: [Int] = []
        
        for (ind, cell) in cells.enumerated() {
            if cell is DefinitionCell {
                let dCell = cell as! DefinitionCell
                if dCell.saved {
                    savedCellIndexes.append(ind)
                }
            }
        }
        
        return savedCellIndexes
    }
    
    func createCellStructs(wordDataResults: [Result]?) -> [DictTableCell]? {
        // Create a list of cell objects that describe cell type and a cell content's location in the Oxford API data structure
        if let cells = self.cells {
            return cells
        }
        
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
    
    func getDefinitionStruct(definitionData: Definition, indexLocation: [Int], type: String) -> DefinitionCell? {
        
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
    
    func getNoteText(notes: [Note]) -> NSAttributedString {
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
    
    func getRegisterText(definitionData: Definition) -> NSAttributedString? {
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

// Extensions for the dictionary table view
extension DictionaryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
}

extension DictionaryViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Return the total number of cells required
        if let cells = self.cells {
            return cells.count
        } else {
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellStruct = cells![indexPath.row]
        let resultIndex = cells![indexPath.row].indexLocation[0]
        var cell: UITableViewCell?
        
        if cellStruct is WordPronounciationCell {
            let cStruct = cellStruct as! WordPronounciationCell
            // Create cell from storyboard prototype cell for word and its pronounciation
            cell = tableView.dequeueReusableCell(
                withIdentifier: K.tables.dictionary.cell.nib.wordPronounciation,
                for: indexPath)
            // Set text
            let wordLabel = cell!.viewWithTag(1) as! UILabel
            let resultNumLabel = cell!.viewWithTag(2) as! UILabel
            let phoneticLabel = cell!.viewWithTag(3) as! UILabel
            wordLabel.attributedText = cStruct.wordText
            resultNumLabel.text = String(cStruct.indexLocation[0] + 1)
            phoneticLabel.attributedText = cStruct.phoneticText
            // Set name label width
            wordLabel.constraintWithIdentifier("wordLabelWidth")!.constant = wordLabel.intrinsicContentSize.width
            // Set result number label width
            resultNumLabel.constraintWithIdentifier("resultNumLabelWidth")!.constant = resultNumLabel.intrinsicContentSize.width
        } else if cellStruct is LexicalCategoryCell {
            let cStruct = cellStruct as! LexicalCategoryCell
            // Create cell from storyboard prototype cell for word category
            cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.nib.category, for: indexPath)
            // Set text
            let categoryLabel = cell!.viewWithTag(1) as! UILabel
            categoryLabel.attributedText = cStruct.categoryText
        } else if cellStruct is DefinitionCell {
            let cStruct = cellStruct as! DefinitionCell
            if cStruct.type == K.dictionaries.oxford.definition.type.primary {
                // Create cell from storyboard prototype cell for primary definition
                cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.nib.primaryDefinition, for: indexPath)
                // Set text
                let primDefNumLabel = cell!.viewWithTag(1) as! UILabel
                let primDefLabel = cell!.viewWithTag(2) as! UILabel
                primDefNumLabel.attributedText = NSAttributedString(string:String(cStruct.indexLocation[2] + 1), attributes: K.stringAttributes.secondary14)
                let defExText = NSMutableAttributedString(attributedString: cStruct.definition)
                defExText.append(cStruct.examples!)
                primDefLabel.attributedText = defExText
                // Set star button as outlined/filled
                let starButton = configureDictStarButton(cell: cell!, cellInd: indexPath.row, isSaved: cStruct.saved)
                // Listen to star button tap and release events
                starButton.setIndexPath(indexPath: indexPath)
                starButton.addTarget(self, action: #selector(didTapStar), for: .touchDown)
                starButton.addTarget(self, action: #selector(didReleaseStar), for: .touchUpInside)
            } else if cStruct.type == K.dictionaries.oxford.definition.type.secondary {
                // Create cell from storyboard prototype cell for secondary/sub definition
                cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.nib.secondaryDefenition, for: indexPath)
                // Set text
                let subDefLabel = cell!.viewWithTag(1) as! UILabel
                let defExText = NSMutableAttributedString(attributedString: cStruct.definition)
                defExText.append(cStruct.examples!)
                subDefLabel.attributedText = defExText
                // Set star button as outlined/filled
                let starButton = configureDictStarButton(cell: cell!, cellInd: indexPath.row, isSaved: cStruct.saved)
                // Listen to star button tap and release events
                starButton.setIndexPath(indexPath: indexPath)
                starButton.addTarget(self, action: #selector(didTapStar), for: .touchDown)
                starButton.addTarget(self, action: #selector(didReleaseStar), for: .touchUpInside)
            } else {
                print("Error: Issue differentiating between primary and secondary definition cells.")
            }
        } else if cellStruct is OriginCell {
            let cStruct = cellStruct as! OriginCell
            // Create cell from storyboard prototype cell for word origin
            cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.nib.origin, for: indexPath)
            // Set text
            let originLabel = cell!.viewWithTag(1) as! UILabel
            originLabel.attributedText = cStruct.etymology
        } else if cellStruct is NoResultCell {
            // TODO: Create dedicated cell to handle cases when a word is not found in the dictionary
            cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.nib.noResult, for: indexPath)
        }
        else {
            print("Error: Cell type could not be determined.")
        }
        
        let containerView = cell!.contentView.subviews[0]
        if (indexPath.row == 0 || (resultIndex != 0 && cells![indexPath.row - 1].indexLocation[0] == resultIndex - 1) ) {
            // Round top corners of first cell. Acts on cell prototype, not its instance.
            containerView.layer.cornerRadius = 10
            containerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
        
        // Logic for last cell in each result. Acts on cell prototype, not its instance.
        if indexPath.row + 1 == cells!.count || cells![indexPath.row + 1].indexLocation[0] == resultIndex + 1 {
            // Round bottom corners
            containerView.layer.cornerRadius = 10
            let bottomCorners = CACornerMask([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            if cellStruct is NoResultCell {
                containerView.layer.maskedCorners = containerView.layer.maskedCorners.union(bottomCorners)
            } else {
                containerView.layer.maskedCorners = bottomCorners
            }
            // Set result bottom margin for cells that don't have etymology info
            if !(cellStruct is OriginCell) {
                containerView.constraintWithIdentifier("nonLastCellBottomMargin")?.constant = 20
            }
        }
        
        // Set result container top margins
        if indexPath.row == 0 {
            containerView.constraintWithIdentifier("resultContainerTopMargin")?.constant = 20
        } else if cells![indexPath.row - 1].indexLocation[0] == resultIndex - 1 {
            containerView.constraintWithIdentifier("resultContainerTopMargin")!.constant = 10
        }
        
        // Set result container bottom margins
        if indexPath.row + 1 == cells!.count {
            containerView.superview!.constraintWithIdentifier("resultContainerBottomMargin")!.constant = 20
        } else if cells![indexPath.row + 1].indexLocation[0] == resultIndex + 1 {
            containerView.superview!.constraintWithIdentifier("resultContainerBottomMargin")!.constant = 0
        }
        
        cell!.layoutIfNeeded()
        
        // TODO: Set star as outlined or filled based on whether word definition is saved for user.
        
        return cell!
        
    }
    
    func configureDictStarButton(cell: UITableViewCell, cellInd: Int, isSaved: Bool) -> dictStarButton {
        let starButton = cell.viewWithTag(3) as! dictStarButton
        if isSaved {
            if let defaultDefinitionIndex = self.defaultDefinitionIndex {
                if cellInd == defaultDefinitionIndex {
                    starButton.tintColor = .orange
                }
            } else {
                starButton.tintColor = UIView().tintColor
            }
            starButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        } else {
            starButton.tintColor = UIView().tintColor
            starButton.setImage(UIImage(systemName: "star"), for: .normal)
        }
        return starButton
    }
    
    func updateCellStructs(userData: FirestoreUserData) {
        // User data may or may not contain saved definitions for a word
        if let starredCellIndexes = self.firestoreManager!.getWordInFirstCollection(for: self.queryWord!, in: userData)?.starredCellIndexes {
            for cellInd in starredCellIndexes {
                let updatedCell = self.cells![cellInd] as! DefinitionCell
                updatedCell.saved = true
                self.cells![cellInd] = updatedCell
            }
        }
    }
    
}

extension DictionaryViewController: OxfordWordDataDelegate {
    
    func didGetWordData(wordData: OxfordWordData) {
        print("found word data in oxford dict")
        // Save wordData to firestore
        self.firestoreManager?.saveWordData(for: self.queryWord!, wordData: wordData)
        // Save wordData locally and generate cell structs
        self.wordData = wordData
        self.cells = createCellStructs(wordDataResults: self.wordData?.results)
        self.firestoreManager?.getUserData()
    }
    
}

extension DictionaryViewController: FirestoreWordDataDelegate {
    
    func didGetWordData(wordData: OxfordWordData?) {
        if let wordData = wordData {
            print("found word data in firestore")
            self.wordData = wordData
            self.cells = createCellStructs(wordDataResults: self.wordData?.results)
            self.firestoreManager?.getUserData()
        } else {
            // No word data found in firestore. Query oxford api and save result to firestore
            var dictionaryManager = OxfordDictionaryManager()
            dictionaryManager.delegate = self
            dictionaryManager.getDefinitionData(word: self.queryWord!)
        }
    }
    
}

extension DictionaryViewController: FirestoreUserDataDelegate {
    
    func didGetUserData(userData: FirestoreUserData?) {
        print("successfully got user data")
        self.dbUserData = userData
        if let userData = userData {
            updateCellStructs(userData: userData)
            // Update default definition index
            if let defaultDefinitionIndex = self.firestoreManager!.getWordInFirstCollection(for: self.queryWord!, in: userData)?.defaultDefinitionIndex {
                self.defaultDefinitionIndex = defaultDefinitionIndex
            }
        }
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
