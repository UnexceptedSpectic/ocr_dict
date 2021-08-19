//
//  ViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 5/29/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit

class LibraryViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionInstructionsLabel: UILabel!
    @IBOutlet weak var topNav: UINavigationItem!
    @IBOutlet weak var collectionsLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var addCollectionButton: UIBarButtonItem!
    
    var firestoreM: FirestoreManager?
    var selectedCollectionIndex: Int?
    
    let gridGapSize: CGFloat = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for updated userData
        State.instance.userDataUpdateDelegates.append(self)
                
        self.firestoreM = FirestoreManager()
        self.firestoreM!.userDataDelegate = self
        self.firestoreM!.getUserData()
        // Start activity indicator
        self.collectionsLoadingIndicator.startAnimating()
        // Disable add collection button
        self.addCollectionButton.isEnabled = false
        
        // Hide instruction label by default
        self.collectionInstructionsLabel.isHidden = true
        
        // Configure collection
        self.collectionView.isHidden = true
        self.collectionView = LibraryCollection.configure(view: self.collectionView)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Enable the navigation bar
        navigationController?.isNavigationBarHidden = false
        
        // Hide back button
        topNav.hidesBackButton = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        collectionView.isHidden = false
    }
    
    @IBAction func didTapSignOut(_ sender: UIBarButtonItem) {
        signOutAndGoHome(navigationController: navigationController)
    }
    
    @IBAction func didTapAddCollection(_ sender: UIBarButtonItem) {
        // Create an alert
        let alert = CollectionCreatorAlert(collectionView: self.collectionView, firestoreM: self.firestoreM!).alert!
        
        // Show/hide add collection instructions label
        self.toggleInstructionsGivenUserData()

        // Show the alert
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func toggleInstructionsGivenUserData() {
        if (State.instance.userData!.collections.count == 0) {
            collectionInstructionsLabel.isHidden = false
        } else {
            collectionInstructionsLabel.isHidden = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // Pass userData and collection index to collection view
        if segue.destination is CollectionViewController {
            let collectionVC = segue.destination as! CollectionViewController
            collectionVC.collectionIndex = self.selectedCollectionIndex
        }
    }
    
}

// Extensions required for configuring collection with template nib/xib. Makes loading collection items more efficient

extension LibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        self.selectedCollectionIndex = indexPath.row
        performSegue(withIdentifier: "LibraryToCollection", sender: self)
    }
}

extension LibraryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return LibraryCollection.getCellSize(collectionFrame: collectionView.frame, desiredRows: 4, desiredCols: 3)
    }
}

extension LibraryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return LibraryCollection.numberOfItems(section: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        LibraryCollection.createCellFor(collectionView: collectionView, indexPath: indexPath)
    }
}

extension LibraryViewController: FirestoreUserDataDelegate {
    
    func didGetUserData(userData: FirestoreUserData?) {
        // Stop activity indicator
        collectionsLoadingIndicator.stopAnimating()
        // Enable add collection button
        addCollectionButton.isEnabled = true
        // Save user data
        State.instance.userData = userData
        // Show/hide collection instructions
        if userData != nil {
            toggleInstructionsGivenUserData()
        } else {
            collectionInstructionsLabel.isHidden = false
        }
        // Reload collection view
        collectionView.reloadData()
    }

}

extension LibraryViewController: UserDataUpdateDelegate {
    func updateViews() {
        self.collectionView.reloadData()
    }
}
