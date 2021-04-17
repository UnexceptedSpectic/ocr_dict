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
    
    var collectionItems: [String] = ["first", "second","first", "second","first", "second","first", "second","first", "second","first", "second","first", "second","first", "second"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        var firestoreM = FirestoreManager()
        firestoreM.userDataDelegate = self
        
        if collectionItems.count > 0 {
            collectionInstructionsLabel.isHidden = true
        }
        
        // Configure collection
        collectionView.isHidden = true
        collectionView.register(CollectionViewCell.nib(nibName: K.collections.library.cell.nib), forCellWithReuseIdentifier: K.collections.library.cell.type)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        
        let layout = UICollectionViewFlowLayout()
        // Specify outer padding of collection
        // layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = CGFloat(0)
        layout.minimumInteritemSpacing = CGFloat(0)
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
                
                self.collectionItems.append((textField?.text)!)
                
                if self.collectionItems.count > 0 {
                    self.collectionInstructionsLabel.isHidden = true
                } else {
                    self.collectionInstructionsLabel.isHidden = false
                }
                
                let indexPath = IndexPath(row: self.collectionItems.count - 1, section: 0)
                self.collectionView.insertItems(at: [indexPath])
            }
        }))
        
        // Configure 'cancel' button
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            alert.dismiss(animated: true, completion: nil)
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
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
        
        return collectionItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: K.collections.library.cell.type, for: indexPath) as! CollectionViewCell

        cell.configure(backgroundColor: K.brand.colors.gray)
        cell.configure(projectName: collectionItems[indexPath.row])
        return cell
    }
    
}

extension LibraryViewController: UICollectionViewDelegateFlowLayout {
     
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // Configure 3 collection items per row and 4 rows
        return CGSize(
            width: round(collectionView.frame.size.width / 3),
            height: round(collectionView.frame.size.height / 4))
    }
    
}

extension LibraryViewController: FirestoreUserDataDelegate {
    
    func didGetUserData(userData: FirestoreUserData?) {
        
    }

}
