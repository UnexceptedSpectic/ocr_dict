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
                print("Reloading table")
                self.collectionTable.reloadData()
                
            }
        }
    }
}

extension CollectionViewController: FirestoreWordsDataDelegate {
    
    func didGetWordsData(wordsData: [OxfordWordData?]) {
        print("Setting words data")
        self.wordsData = wordsData
        self.wordsDataGetterGroup!.leave()
    }
    
}

extension CollectionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "CollectionToLearner", sender: self)
    }
    
}

extension CollectionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let userData = self.userData {
            return userData.collections[self.collectionIndex!].words.count
        } else {
            return 0;
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.collectionTable.dequeueReusableCell(withIdentifier: K.tables.collection.cell.nib.wordSummary)!
        let wordLabel = cell.viewWithTag(1) as! UILabel
        let modDateLabel = cell.viewWithTag(2) as! UILabel
        let mainDefinitionLabel = cell.viewWithTag(3) as! UILabel
        let userWordData = userData!.collections[self.collectionIndex!].words[indexPath.row]
        wordLabel.text = userWordData.word
        modDateLabel.text = getDateOrTime(dateTime: userWordData.dateModified)
        // TODO: Set mainDefinitionLabel text
        var defaultDefinitionCellIndex: Int
        if let ddci = userWordData.defaultDefinitionCellIndex {
            defaultDefinitionCellIndex = ddci
        } else {
            // Use the first definition cell, which occurs after the first wordPronounciationCell and categoryCell cells
            defaultDefinitionCellIndex = 2
        }
        if let wordsData = self.wordsData {
            mainDefinitionLabel.text = firestoreManager!.getDefinition(wordData: wordsData[indexPath.row]!, cellIndex: defaultDefinitionCellIndex).firstUppercased + "."
        }
        return cell;
    }
    
}

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
}
