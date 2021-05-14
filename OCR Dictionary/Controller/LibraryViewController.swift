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
    var userData: FirestoreUserData?
    
    let gridGapSize: CGFloat = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        firestoreM = FirestoreManager()
        firestoreM!.userDataDelegate = self
        firestoreM!.getUserData()
        // Start activity indicator
        collectionsLoadingIndicator.startAnimating()
        // Disable add collection button
        addCollectionButton.isEnabled = false
        
        // Hide instruction label by default
        collectionInstructionsLabel.isHidden = true
        
        // Configure collection
        collectionView.isHidden = true
        collectionView.register(CollectionViewCell.nib(nibName: K.collections.library.cell.nib), forCellWithReuseIdentifier: K.collections.library.cell.type)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        // Allow scrolling/pulling beyond vertical bounds
        collectionView.alwaysBounceVertical = true;
        
        let layout = UICollectionViewFlowLayout()
        // Specify outer padding of collection
         layout.sectionInset = UIEdgeInsets(
            top: gridGapSize,
            left: gridGapSize,
            bottom: gridGapSize,
            right: gridGapSize
        )
        layout.minimumLineSpacing = gridGapSize
        layout.minimumInteritemSpacing = gridGapSize
        collectionView.collectionViewLayout = layout
        
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

    @IBAction func didTapCaptureButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "homeToSnapper", sender: self)
    }
    
    @IBAction func addCollectionItem(_ sender: UIBarButtonItem) {
        // Create alert controller
        let alert = UIAlertController(title: "Create a new Collection", message: "Collection name", preferredStyle: .alert)

        // Add the text input field
        alert.addTextField(configurationHandler: nil)

        // Configure 'ok' button
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            // Add collection item if collection name isn't empty
            if !(textField?.text!.isEmpty)! {
                
                let dtNow = getDatetimeString()
                let newCollection = Collection(
                    name: (textField?.text)!,
                    dateCreated: dtNow,
                    dateModified: dtNow,
                    words: []
                )
                if self.userData != nil {
                    self.userData!.collections.append(newCollection)
                } else {
                    self.userData = FirestoreUserData(collections: [newCollection])
                }
                
                // Save data to firestore
                self.firestoreM!.saveUserData(updatedUserData: self.userData!)
                
                // Show/hide add collection instructions label
                self.toggleInstructionsGivenUserData()
                
                let indexPath = IndexPath(row: self.userData!.collections.count - 1, section: 0)
                self.collectionView.insertItems(at: [indexPath])
            }
        }))
        
        // Configure 'cancel' button
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            alert.dismiss(animated: true, completion: nil)
        }))

        // Show the alert
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func toggleInstructionsGivenUserData() {
        if self.userData!.collections.count == 0 {
            collectionInstructionsLabel.isHidden = false
        } else {
            collectionInstructionsLabel.isHidden = true
        }
    }
    
}

// Extensions required for configuring collection with template nib/xib. Makes loading collection items more efficient

extension LibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        print("collection item tapped!")
        
        performSegue(withIdentifier: "LibraryToCollection", sender: self)
        
    }
}

extension LibraryViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let userData = self.userData {
            return userData.collections.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: K.collections.library.cell.type, for: indexPath) as! CollectionViewCell

        cell.configure(backgroundColor: K.brand.colors.gray)
        cell.configure(collectionName: self.userData!.collections[indexPath.row].name)
        return cell
    }
    
}

extension LibraryViewController: UICollectionViewDelegateFlowLayout {
     
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // Configure 3 collection items per row and 4 rows. Subtract grid spacing e.g. 4 spaces/3 cells.
        // TODO: Add different config for landscape mode, or disable the latter.
        return CGSize(
            width: floor(collectionView.frame.size.width / 3 - 4/3 * self.gridGapSize),
            height: floor(collectionView.frame.size.height / 4 - 5/4 * self.gridGapSize)
        )
    }
    
}

extension LibraryViewController: FirestoreUserDataDelegate {
    
    func didGetUserData(userData: FirestoreUserData?) {
        // Stop activity indicator
        collectionsLoadingIndicator.stopAnimating()
        // Enable add collection button
        addCollectionButton.isEnabled = true
        // Save user data
        self.userData = userData
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
