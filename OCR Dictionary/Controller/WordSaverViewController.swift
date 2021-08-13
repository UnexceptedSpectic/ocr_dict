//
//  WordSaverViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 3/26/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import UIKit

class WordSaverViewController: UIViewController {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var createCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var word: String?
    var savedCellIndexes: [Int]?
    var defaultDefinitionIndex: Int?
    var dbSelectedCollectionIndexes: Set<Int>?
    var selectedCollectionIndexes: Set<Int>?
    var firestoreManager = FirestoreManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Highlight cells based on the word's presence in a collection
        self.dbSelectedCollectionIndexes = Set(0...((State.instance.userData?.collections.count)! - 1))
            .filter({ (State.instance.userData?.collections[$0].words
                        .filter({ $0.word == word }).count)! > 0
            })
        self.selectedCollectionIndexes = self.dbSelectedCollectionIndexes
        // Configure collection
        self.collectionView = LibraryCollection.configure(view: self.collectionView)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    
    @IBAction func didTapApply(_ sender: UIButton) {
        // Validate collection selection(s)
        if (self.selectedCollectionIndexes!.isEmpty) {
            // TODO: Populate error label with message
            return
        }
        // Remove word from unselected collections
        self.dbSelectedCollectionIndexes?.forEach({ (ind) in
            if (!self.selectedCollectionIndexes!.contains(ind)) {
                State.instance.userData = self.firestoreManager.deleteWordFromCollection(userData: State.instance.userData!, word: self.word!, collectionInd: ind)!
            }
        })
        // Save userData to firestore and update app state
        var updatedUserData = State.instance.userData
        self.selectedCollectionIndexes!.forEach({ (ind) in
            updatedUserData = self.firestoreManager.initOrUpdateUserData(
                add: self.word!,
                to: (self.collectionView.cellForItem(at: IndexPath(row: ind, section: 0)) as! CollectionViewCell).titleLabel.text!,
                usingTemplate: updatedUserData,
                newStarredCellIndexes: self.savedCellIndexes!,
                newDefaultDefinitionIndex: self.defaultDefinitionIndex)
        })
        // TODO: make async?
        self.firestoreManager.saveUserData(updatedUserData: updatedUserData!)
        State.instance.userData = updatedUserData
        // Notify views that rely on state userData of update
        State.instance.userDataUpdateDelegates.forEach({ $0.updateViews() })
        dismiss(animated: true)
    }
    
    @IBAction func didTapCancel(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func didTapCreateCollection(_ sender: UIButton) {
        // Create an alert
        let alert = CollectionCreatorAlert(collectionView: self.collectionView, firestoreM: self.firestoreManager).alert!

        // Show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    
}

extension WordSaverViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if (self.selectedCollectionIndexes!.contains(indexPath.row)) {
            self.selectedCollectionIndexes!.remove(indexPath.row)
        } else {
            self.selectedCollectionIndexes!.insert(indexPath.row)
        }
        collectionView.reloadData()
    }
}

extension WordSaverViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return LibraryCollection.getCellSize(collectionFrame: collectionView.frame, desiredRows: 3, desiredCols: 2)
    }
}

extension WordSaverViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return LibraryCollection.numberOfItems(section: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = LibraryCollection.createCellFor(collectionView: collectionView, indexPath: indexPath)
        let defaultBackgroundColor = cell.getBackgroundColor()
        if (self.selectedCollectionIndexes!.contains(indexPath.row)) {
            cell.configure(backgroundColor: .blue)
        } else {
            cell.configure(backgroundColor: defaultBackgroundColor!)
        }
        return cell
    }
}
