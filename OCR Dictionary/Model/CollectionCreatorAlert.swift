//
//  CollectionCreatorAlert.swift
//  OCR Dictionary
//
//  Created by Philip on 8/11/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import Foundation
import UIKit

class CollectionCreatorAlert {
    
    var alert: UIAlertController?
    
    init(collectionView: UICollectionView, firestoreM: FirestoreManager) {
        // Create alert controller
        self.alert = UIAlertController(title: "Create a new Collection", message: "Collection name", preferredStyle: .alert)
        
        // Add the text input field
        alert!.addTextField(configurationHandler: nil)

        // Configure 'ok' button
        alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
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
                if State.instance.userData != nil {
                    State.instance.userData!.collections.append(newCollection)
                } else {
                    State.instance.userData = FirestoreUserData(collections: [newCollection])
                }
                
                // Save data to firestore
                firestoreM.saveUserData(updatedUserData: State.instance.userData!)
                
                let indexPath = IndexPath(row: State.instance.userData!.collections.count - 1, section: 0)
                collectionView.insertItems(at: [indexPath])
            }
        }))
        
        // Configure 'cancel' button
        alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            self.alert!.dismiss(animated: true, completion: nil)
        }))
    }
}
