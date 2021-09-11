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
    
    @IBOutlet weak var dictionaryTableView: UITableView!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var previousController: UIViewController?
    var queryWord: String?
    var wordData: OxfordWordData?
    var wordDataGetterGroup: DispatchGroup?
    var suggestionsGetterGroup: DispatchGroup?
    var definitionTableGroup = DispatchGroup()
    var cells: [DictTableCell]?
    var firestoreManager: FirestoreManager?
    var oxfordDictionaryManager = OxfordDictionaryManager()
    var suggestions: [String]?
    
    // For managing definition star state
    var starHeldDown: Bool = false
    var defaultDefinitionCellIndex: Int?
    var defaultDefinitionCellIndexUpdatePending: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Determine calling/previous view controller
        self.previousController = navigationController!.viewControllers[navigationController!.viewControllers.count - 1]
        
        // Hide activity indicator
        self.activityIndicator.isHidden = true
        
        // Configure oxford deletages
        self.oxfordDictionaryManager.headwordDelegate = self
        
        // Configure save button
        self.saveBarButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray], for: .disabled)
        
        // Disable save button until local data diverges from db version
        self.saveBarButton.isEnabled = false
        
        // Fetch word data from firestore, else oxford api, then reload table
        fetchWordDataReloadTable()
    }
    
    func fetchWordDataReloadTable() {
        // Logic for fetching word data. Always query firestore first
        self.firestoreManager = FirestoreManager()
        self.firestoreManager!.wordDataDelegate =  self
        self.firestoreManager!.userDataDelegate = self
        
        // Perform firestore/oxford dict word queries on background thread
        self.wordDataGetterGroup = DispatchGroup()
        self.wordDataGetterGroup!.enter()
        
        DispatchQueue.main.async {
            // Fetch word cells from firestore
            print("starting to get user word cells")
            self.firestoreManager!.getWordData(for: self.queryWord!)
        }
        
        // Start loading table after word and user? data is obtained (all dispatch group tasks are completed/leave() is called)
        DispatchQueue.main.async {
            
            self.wordDataGetterGroup!.notify(queue: .main) {
                
                // Set up dict table view and reload view, now that data has been obtained
                self.dictionaryTableView.delegate = self
                self.dictionaryTableView.dataSource = self
                self.activityIndicator.isHidden = true
                self.dictionaryTableView.reloadData()
                
            }
        }
    }
    
    @IBAction func didTapSave(_ sender: UIBarButtonItem) {
        if (self.defaultDefinitionCellIndex == nil) {
            // Use the first definition cell, which occurs after the first wordPronounciationCell and categoryCell cells
            self.defaultDefinitionCellIndex = 2
            // Set defaultDefinition cell as saved and show it in table
            (self.cells![self.defaultDefinitionCellIndex!] as! DefinitionCell).saved = true
            self.dictionaryTableView.reloadData()
        }
        let presentingViewController = navigationController!.viewControllers[navigationController!.viewControllers.count - 2]
        if (presentingViewController is CollectionViewController) {
            let collectionViewController = presentingViewController as! CollectionViewController
            let updatedUserData = self.firestoreManager!.initOrUpdateUserData(
                add: self.queryWord!,
                to: State.instance.userData!.collections[collectionViewController.collectionIndex!].name,
                usingTemplate: State.instance.userData!,
                newStarredCellIndexes: self.getSavedCellIndexes(cells: self.cells!),
                newDefaultDefinitionIndex: self.defaultDefinitionCellIndex)
            self.firestoreManager!.saveUserData(updatedUserData: updatedUserData)
            State.instance.userData = updatedUserData
            // Notify views that rely on state userData of update
            State.instance.userDataUpdateDelegates.forEach({ $0.updateViews() })
            navigationController?.popViewController(animated: true)
        } else {
            // Use word saver to allow user to specify target collection
            performSegue(withIdentifier: "DictToSaver", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.destination is WordSaverViewController {
            let saverVC = segue.destination as! WordSaverViewController
            saverVC.word = queryWord!
            saverVC.savedCellIndexes = self.getSavedCellIndexes(cells: self.cells!)
            saverVC.defaultDefinitionIndex = self.defaultDefinitionCellIndex
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
                    self.defaultDefinitionCellIndexUpdatePending = true
                    // Haptic/vibrate feedback
                    if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
                        UISelectionFeedbackGenerator().selectionChanged()
                    } else {
                        AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate) {}
                    }
                    DispatchQueue.main.async {
                        // Refresh table view
                        self.dictionaryTableView.setNeedsDisplay()
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
        
        if self.defaultDefinitionCellIndexUpdatePending {
            // Sufficient hold event
            // Unsave previous default definition cell
            if let previousDefaultDefinitionCellIndex = self.defaultDefinitionCellIndex {
                let previousDefaultDefinitionCell = self.cells![previousDefaultDefinitionCellIndex] as! DefinitionCell
                previousDefaultDefinitionCell.saved = false
                self.cells![previousDefaultDefinitionCellIndex] = previousDefaultDefinitionCell
            }
            // Save current cell
            cell.saved = true
            // Update index
            self.defaultDefinitionCellIndex = cellIndex
        } else {
            // Tap event
            if (cell.saved) {
                cell.saved = false
                if self.defaultDefinitionCellIndex == cellIndex {
                    self.defaultDefinitionCellIndex = nil
                }
            } else {
                cell.saved = true
            }
        }
        
        // Reset definition cell touch state
        self.defaultDefinitionCellIndexUpdatePending = false
        
        self.cells![cellIndex] = cell
        
        // Enable/disable save button
        setSaveButtonState()
        
        // Refresh table view
        self.dictionaryTableView.reloadData()
    }
    
    func setSaveButtonState() {
        // Enable/disable save button
        let localStarredCellIndexes = getSavedCellIndexes(cells: self.cells!)
        if let dbUserData = State.instance.userData {
            if let firstCollection = self.firestoreManager!.getWordInFirstCollection(for: self.queryWord!, in: dbUserData) {
                let dbStarredCellIndexes = firstCollection.starredCellIndexes
                let dbDefaultDefinitionIndex = firstCollection.defaultDefinitionCellIndex
                // Enable save button if local user data differs from that in the db
                if (localStarredCellIndexes != dbStarredCellIndexes || self.defaultDefinitionCellIndex != dbDefaultDefinitionIndex) {
                    self.saveBarButton.isEnabled = true
                } else {
                    self.saveBarButton.isEnabled = false
                }
            } else {
                // Enable save button when the word is not found in any user collection in the db
                if (!localStarredCellIndexes.isEmpty || self.defaultDefinitionCellIndex != nil) {
                    self.saveBarButton.isEnabled = true
                } else {
                    self.saveBarButton.isEnabled = false
                }
            }
        } else {
            // Enable save button when user data could not be obtained from the database/prior to it having been asynchronously fetched
            if (!localStarredCellIndexes.isEmpty || self.defaultDefinitionCellIndex != nil) {
                self.saveBarButton.isEnabled = true
            } else {
                self.saveBarButton.isEnabled = false
            }
        }
    }
    
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
    
    func getCellStructs(wordDataResults: [WordResult]?) -> [DictTableCell]? {
        // Create a list of cell objects that describe cell type and a cell content's location in the Oxford API data structure
        if let cells = self.cells {
            return cells
        } else {
            return DictTableCellFactory.createCellStructs(wordDataResults: wordDataResults)
        }
        
    }
    
    func updateHistory() {
        let now = getDatetimeString()
        if !(self.previousController! is CollectionViewController) {
            let wordAtSameTimeExists = State.instance.userData!.history.filter({ $0.word == self.queryWord && getTime(dateTime: $0.date) == getTime(dateTime: now) }).count > 0
            if !wordAtSameTimeExists {
                State.instance.userData!.history.insert(WordLookup(word: self.queryWord!, date: now), at: 0)
                self.firestoreManager!.saveUserData(updatedUserData: State.instance.userData!)
            }
        }
    }
    
}

// Extensions for the dictionary table view
extension DictionaryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = self.cells![indexPath.row]
        if cell is RootWordCell {
            self.activityIndicator.isHidden = false
            self.queryWord = (cell as! RootWordCell).word.string
            self.cells = nil
            self.fetchWordDataReloadTable()
        }
        
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
            wordLabel.firstConstraintWithIdentifier("wordLabelWidth")!.constant = wordLabel.intrinsicContentSize.width
            // Set result number label width
            resultNumLabel.firstConstraintWithIdentifier("resultNumLabelWidth")!.constant = resultNumLabel.intrinsicContentSize.width
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
            cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.nib.noResult, for: indexPath)
            if self.suggestions == nil {
                // Get word suggestions on background thread
                self.activityIndicator.isHidden = false
                self.suggestionsGetterGroup = DispatchGroup()
                self.suggestionsGetterGroup!.enter()
                DispatchQueue.main.async {
                    self.oxfordDictionaryManager.getHeadword(word: self.queryWord!)
                    // Wait for completion of above task
                    self.suggestionsGetterGroup!.notify(queue: .main) {
                        self.activityIndicator.isHidden = true
                        self.dictionaryTableView.reloadData()
                    }
                }
            }
        } else if cellStruct is RootWordCell {
            let cStruct = cellStruct as! RootWordCell
            cell = tableView.dequeueReusableCell(withIdentifier: K.tables.dictionary.cell.nib.rootWord, for: indexPath)
            let rootWordLabel = cell?.viewWithTag(1) as! UILabel
            rootWordLabel.attributedText = cStruct.word
        }
        else {
            print("Error: Cell type could not be determined.")
        }
        
        // Don't highlight cell on tap
        cell!.selectionStyle = .none
        
        // Modify cell corner curves and cell-container margins. Changes act on cell prototype, not its instance, so each cell should have these properties configured here.
        // If this section needs to be modified, note that adding constraints may result in conflicts automatically generated cell constraints e.g. 'UIView-Encapsulated-Layout-Height ... (active)' error. To solve this, 'reduce' the priority of your custom constraint in the storyboard e.g. 999 instead of 1000.
        let containerView = cell!.contentView.subviews[0]
        let firstCell: Bool = (indexPath.row == 0)
        let lastCell: Bool = (indexPath.row + 1 == cells!.count)
        let followingFirstResultCell: Bool = (resultIndex != 0 && cells![indexPath.row - 1].indexLocation[0] == resultIndex - 1)
        let lastCellInResult: () -> Bool = {(self.cells![indexPath.row + 1].indexLocation[0] == resultIndex + 1)}
        
        // For first cell of each 'result' sequence of cells OR RootWord cell.
        if (firstCell || followingFirstResultCell) {
            // Round top corners
            containerView.layer.cornerRadius = 10
            containerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
        
        // For last cell in each result.
        if (lastCell || lastCellInResult()) {
            // Round bottom corners
            containerView.layer.cornerRadius = 10
            let bottomCorners = CACornerMask([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            // Round all corners for NoResult and RootWord cells
            if (cellStruct is NoResultCell || cellStruct is RootWordCell) {
                containerView.layer.maskedCorners = containerView.layer.maskedCorners.union(bottomCorners)
            } else {
                containerView.layer.maskedCorners = bottomCorners
            }
            // Set result bottom margin for cells that don't have etymology info
            if cellStruct is DefinitionCell {
                cell!.contentView.firstConstraintWithIdentifier("definitionBottomMargin")!.constant = 20
                cell!.contentView.firstConstraintWithIdentifier("resultContainerBottomMargin")!.constant = 20
            }
        }
                
        // Set result container top margins
        if firstCell {
            cell!.contentView.firstConstraintWithIdentifier("resultContainerTopMargin")!.constant = 20
        } else if followingFirstResultCell {
            cell!.contentView.firstConstraintWithIdentifier("resultContainerTopMargin")!.constant = 10
            if (resultIndex == 1 && cellStruct is RootWordCell) {
                cell!.contentView.firstConstraintWithIdentifier("resultContainerTopMargin")!.constant = 20
            }
        }
        
        // Set result container bottom margins
        if lastCell {
            cell!.contentView.firstConstraintWithIdentifier("resultContainerBottomMargin")!.constant = 20
        } else if lastCellInResult() {
            cell!.contentView.firstConstraintWithIdentifier("resultContainerBottomMargin")!.constant = 0
        }
        
        return cell!
        
    }
    
    func configureDictStarButton(cell: UITableViewCell, cellInd: Int, isSaved: Bool) -> dictStarButton {
        let starButton = cell.viewWithTag(3) as! dictStarButton
        if isSaved {
            if let defaultDefinitionCellIndex = self.defaultDefinitionCellIndex {
                if cellInd == defaultDefinitionCellIndex {
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
        // Update table with a user's data, if the user has starred definitions of the word before
        if let firstCollection = self.firestoreManager!.getWordInFirstCollection(for: self.queryWord!, in: userData) {
            // Update starred indexes
            for cellInd in firstCollection.starredCellIndexes {
                let updatedCell = self.cells![cellInd] as! DefinitionCell
                updatedCell.saved = true
                self.cells![cellInd] = updatedCell
            }
            // Update default definition index
            self.defaultDefinitionCellIndex = firstCollection.defaultDefinitionCellIndex!
        }
    }
    
}

extension DictionaryViewController: OxfordHeadwordDelegate {
    func didGetHeadwords(headwords: [String]) {
        self.suggestions = headwords
        // Create a dedicated HeadwordCell for each suggested headword
        self.suggestions!.forEach({ self.cells!.append(RootWordCell(
                                                        indexLocation: [self.cells!.count],
                                                        word: NSAttributedString(
                                                            string: $0,
                                                            attributes: K.stringAttributes.heading2))) })
        self.suggestionsGetterGroup!.leave()
    }
}

extension DictionaryViewController: OxfordWordDataDelegate {
    
    func didGetWordData(wordData: OxfordWordData) {
        print("found word data in oxford dict")
        // Save wordData to firestore
        self.firestoreManager?.saveWordData(for: self.queryWord!, wordData: wordData)
        // Save wordData locally and generate cell structs
        self.wordData = wordData
        self.cells = self.getCellStructs(wordDataResults: self.wordData?.results)
        if State.instance.userData == nil {
            self.firestoreManager!.getUserData()
        } else {
            self.updateHistory()
            self.updateCellStructs(userData: State.instance.userData!)
            self.wordDataGetterGroup!.leave()
        }
    }
    
}

extension DictionaryViewController: FirestoreWordDataDelegate {
    
    func didGetWordData(wordData: OxfordWordData?) {
        if let wordData = wordData {
            print("found word data in firestore")
            self.wordData = wordData
            self.cells = self.getCellStructs(wordDataResults: self.wordData?.results)
            if State.instance.userData == nil {
                self.firestoreManager!.getUserData()
            } else {
                self.updateHistory()
                self.updateCellStructs(userData: State.instance.userData!)
                self.wordDataGetterGroup!.leave()
            }
        } else {
            // No word data found in firestore. Query oxford api and save result to firestore
            self.oxfordDictionaryManager.wordDataDelegate = self
            self.oxfordDictionaryManager.getDefinitionData(word: self.queryWord!)
        }
    }
    
}

extension DictionaryViewController: FirestoreUserDataDelegate {
    
    func didGetUserData(userData: FirestoreUserData?) {
        print("successfully got user data")
        State.instance.userData = userData
        self.updateHistory()
        self.updateCellStructs(userData: State.instance.userData!)
        self.wordDataGetterGroup!.leave()
    }
    
}

extension DictionaryViewController: UserDataUpdateDelegate {
    func updateViews() {
        self.setSaveButtonState()
    }
}
