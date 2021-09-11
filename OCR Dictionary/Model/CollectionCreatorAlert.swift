//
//  CollectionCreatorAlert.swift
//  OCR Dictionary
//
//  Created by Philip on 8/11/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import Foundation
import UIKit

struct UIHandlers {
    let handlers: [(_ callingClass: Any) -> ()]
    let callingClass: Any
}

class CollectionCreatorAlert {
    
    var alert: UIAlertController?
    
    init(collectionView: UICollectionView, firestoreM: FirestoreManager, uiHandlers: UIHandlers?) {
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
                // Add collection to user data
                State.instance.userData!.collections.append(newCollection)
                
                // Save data to firestore
                firestoreM.saveUserData(updatedUserData: State.instance.userData!)
                
                let indexPath = IndexPath(row: State.instance.userData!.collections.count - 1, section: 0)
                collectionView.insertItems(at: [indexPath])
                
                // Call callingClass-specific handlers
                if uiHandlers != nil {
                    uiHandlers!.handlers.forEach({ $0(uiHandlers!.callingClass) })
                }
            }
        }))
        
        // Configure 'cancel' button
        alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            self.alert!.dismiss(animated: true, completion: nil)
        }))
    }
}
