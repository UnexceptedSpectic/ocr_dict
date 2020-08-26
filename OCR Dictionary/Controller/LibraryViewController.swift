//
//  ViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 5/29/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit
import Firebase

class LibraryViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionInstructionsLabel: UILabel!

    var collectionItems: [String] = ["first", "second","first", "second","first", "second","first", "second","first", "second","first", "second","first", "second","first", "second"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if collectionItems.count > 0 {
            collectionInstructionsLabel.isHidden = true
        }
        
        // Configure collection
        collectionView.isHidden = true
        collectionView.register(LibraryCollectionViewCell.nib(), forCellWithReuseIdentifier: LibraryCollectionViewCell.identifier)
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
    
    override func viewDidAppear(_ animated: Bool) {
        collectionView.isHidden = false
    }

    @IBAction func didTapCaptureButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "homeToSnapper", sender: self)
    }
    
    @IBAction func addCollectionItem(_ sender: UIButton) {
        // Create alert controller
        let alert = UIAlertController(title: "Create a new Project", message: "Enter project name", preferredStyle: .alert)

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
    
    @IBAction func didTapLogout(_ sender: UIButton) {
    
        do {
            try Auth.auth().signOut()
            print("signing out")
            self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        } catch let error as NSError {
            print("Error signing out: \(error).")
        }
    
    }
    
}

// Extensions required for configuring collection with template nib/xib. Makes loading collection items more efficient

extension LibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        print("collection item tapped!")
        
        // TODO: seque to new page with table view of collection's words
        // include search bar at top
    }
}

extension LibraryViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LibraryCollectionViewCell.identifier, for: indexPath) as! LibraryCollectionViewCell

        cell.configure(backgroundColor: LibraryCollectionViewCell.backgroundColors["default"]!)
        cell.configure(projectName: collectionItems[indexPath.row])
        return cell
    }
    
}

extension LibraryViewController: UICollectionViewDelegateFlowLayout {
     
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Configure three collection items per row
        // and ~ heigh of 120 - varies by screen size to prevent cutoff at bottom
        return CGSize(width: collectionView.frame.size.width/3, height: collectionView.frame.size.height / round(collectionView.frame.size.height / 120))
    }
    
}
