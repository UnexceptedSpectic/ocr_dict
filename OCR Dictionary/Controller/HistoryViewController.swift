//
//  HistoryViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 8/18/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    // TODO: add filter option for unique words
    @IBOutlet weak var historyTable: UITableView!
    let firestoreManager = FirestoreManager()
    var selectedHistoryIndexes: Set<Int> = Set()
    var historyDaysWords: [String: [WordLookup]] = Dictionary()
    var orderedHistoryDays: [String] = []
    var inEditMode: Bool = false
    var selectedWord: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for updated userData
        State.instance.userDataUpdateDelegates.append(self)
        
        // Initialize history data
        if State.instance.userData != nil {
            self.filterHistoryData(searchText: searchBar.text)
        } else {
            print("State userData nil in HistoryViewController")
        }
        
        // Configure search bar delegate
        self.searchBar.delegate = self
        
        // Configure table delegate and data source
        self.historyTable.delegate = self
        self.historyTable.dataSource = self
        
        // Handle closing keyboard
        self.historyTable.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didTapHistoryTable)))
    }
    
    func filterHistoryData(searchText: String?) {
        // Populate dict of days to words, using cached userData
        self.historyDaysWords.removeAll()
        State.instance.userData!.history.forEach({ (wordLookup) in
            let date = getDateString(dateTime: wordLookup.date)
            if searchText == nil || searchText!.isEmpty || wordLookup.word.lowercased().contains(searchText!.lowercased()) {
                if self.historyDaysWords[date] != nil {
                    self.historyDaysWords[date]!.append(wordLookup)
                } else {
                    self.historyDaysWords[date] = [wordLookup]
                }
            }
        })
        
        // Order search days from most recent to not
        self.orderedHistoryDays = Array(self.historyDaysWords.keys)
        let containsToday = self.orderedHistoryDays.contains("Today")
        if containsToday {
            self.orderedHistoryDays = orderedHistoryDays.filter({ $0 != "Today" })
        }
        self.orderedHistoryDays.sort(
            by: {
                getDate(dateString: $0)
                < getDate(dateString: $1)
            })
        if containsToday {
            self.orderedHistoryDays.insert("Today", at: 0)
        }
    }
    
    @objc func didTapHistoryTable(sender: UITapGestureRecognizer) {
        // Close keyboard on tap anywhere in suggestionTable
        if sender.state == .ended {
            self.view.endEditing(true)
        }
        sender.cancelsTouchesInView = false
    }
    
    @IBAction func didTapEdit(_ sender: UIBarButtonItem) {
        self.inEditMode = !self.inEditMode
        self.historyTable.reloadData()
        sender.title = sender.title == "Edit" ? "Cancel" : "Edit"
    }
    
    @IBAction func didTapStatus(_ sender: HistoryStatusButton) {
        // HistoryStatusButton filters out touch events when a word is not saved
        // TODO: set library search input to contain word and segue to library
        print("hit because saved")
    }
    
    func getHistoryIndex(historyTable: UITableView, indexPath: IndexPath) -> Int {
        var indexInHistory = -1
        for previousSectionIndex in 0..<indexPath.section {
            indexInHistory += historyTable.numberOfRows(inSection: previousSectionIndex)
        }
        indexInHistory += indexPath.row + 1
        return indexInHistory
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is DictionaryViewController {
            let dictVc = segue.destination as! DictionaryViewController
            dictVc.queryWord = self.selectedWord!.lowercased()
        }
    }
}

extension HistoryViewController: UserDataUpdateDelegate {
    func updateViews() {
        DispatchQueue.main.async {
            self.searchBar.text = nil
            self.filterHistoryData(searchText: nil)
            self.historyTable.reloadData()            
        }
    }
}

extension HistoryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // Create a section for each unique day for which at least one history item exists
        if State.instance.userData != nil {
            return self.historyDaysWords.keys.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // get number of words for a 'section' day
        if State.instance.userData != nil {
            return self.historyDaysWords[self.orderedHistoryDays[section]]!.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let labelView = UILabel()
        labelView.text = self.orderedHistoryDays[section]
        labelView.textAlignment = .center
        labelView.textColor = .label
        labelView.backgroundColor = .systemBackground
        return labelView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let wordLookup = self.historyDaysWords[self.orderedHistoryDays[indexPath.section]]![indexPath.row]
        let cell = self.historyTable.dequeueReusableCell(withIdentifier: K.tables.history.cell.nib.value)!
        let indexInHistory = self.getHistoryIndex(historyTable: tableView, indexPath: indexPath)
        let container = cell.viewWithTag(1)!
        let wordLabel = cell.viewWithTag(2) as! UILabel
        let timeLabel = cell.viewWithTag(3) as! UILabel
        let selectRowView = cell.viewWithTag(4)
        let selectionImage = cell.viewWithTag(5) as! UIImageView
        let statusImage = cell.viewWithTag(6) as! UIImageView
        let statusButton = cell.viewWithTag(7) as! HistoryStatusButton
        wordLabel.text = wordLookup.word
        timeLabel.text = getTime(dateTime: wordLookup.date)
        
        // Round container corners for each cell
        container.layer.cornerRadius = 10
        container.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        // set larger bottom margin for last cell
        if (indexPath.section == tableView.numberOfSections - 1 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1) {
            cell.firstConstraintWithIdentifier("bottomContainerMargin")!.constant = 20
        } else {
            cell.firstConstraintWithIdentifier("bottomContainerMargin")!.constant = 5
        }
        
        // Don't highlight cell on selection
        cell.selectionStyle = .none
        
        // Show cells in their correct editing mode
        if self.inEditMode {
            selectRowView!.isHidden = false
        } else {
            selectRowView!.isHidden = true
        }
        
        //
        if self.selectedHistoryIndexes.contains(indexInHistory) {
            selectionImage.image = UIImage(systemName: "circle.fill")
        } else {
            selectionImage.image = UIImage(systemName: "circle")
        }
        // Set word status
            // Word saved in at least one collection
        if firestoreManager.getWordInFirstCollection(for: wordLookup.word, in: State.instance.userData!) != nil {
            statusButton.status = HistoryStatusButton.SavedStatus.SAVED
            statusImage.image = UIImage(systemName: "bookmark.fill")
        } else {
            statusButton.status = HistoryStatusButton.SavedStatus.NOT_SAVED
            statusImage.image = .none
        }
        
        return cell
    }

}

extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.section, indexPath.row)
        if self.inEditMode {
            // Select row
            let indexInHistory = self.getHistoryIndex(historyTable: tableView, indexPath: indexPath)
            if !self.selectedHistoryIndexes.contains(indexInHistory) {
                self.selectedHistoryIndexes.insert(indexInHistory)
            } else {
                self.selectedHistoryIndexes.remove(indexInHistory)
            }
            tableView.reloadData()
        } else {
            // Segue to dict
            self.selectedWord = self.historyDaysWords[self.orderedHistoryDays[indexPath.section]]![indexPath.row].word
            performSegue(withIdentifier: "HistoryToDict", sender: self)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Close keyboard on scroll
        self.view.endEditing(true)
    }
}

extension HistoryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterHistoryData(searchText: searchBar.text)
        self.historyTable.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Close keyboard on search button click
        self.view.endEditing(true)
    }
}
