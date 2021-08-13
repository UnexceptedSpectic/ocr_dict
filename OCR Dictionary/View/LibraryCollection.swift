//
//  LibraryCollection.swift
//  OCR Dictionary
//
//  Created by Philip on 8/9/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import Foundation
import UIKit

class LibraryCollection {
    
    static let gridGapSize: CGFloat = 10
    
    static func configure(view: UICollectionView) -> UICollectionView {
        let v = view
        v.register(CollectionViewCell.nib(nibName: K.collections.library.cell.nib), forCellWithReuseIdentifier: K.collections.library.cell.type)
        v.showsVerticalScrollIndicator = false
        // Allow scrolling/pulling beyond vertical bounds
        v.alwaysBounceVertical = true;
        // Configure cell spacing
        let layout = UICollectionViewFlowLayout()
        // Outer padding
        layout.sectionInset = UIEdgeInsets(
            top: LibraryCollection.gridGapSize,
            left: LibraryCollection.gridGapSize,
            bottom: LibraryCollection.gridGapSize,
            right: LibraryCollection.gridGapSize
        )
        // Inner spacing
        layout.minimumLineSpacing = LibraryCollection.gridGapSize
        layout.minimumInteritemSpacing = LibraryCollection.gridGapSize
        v.collectionViewLayout = layout
        return v
    }
        
    static func getCellSize(collectionFrame: CGRect, desiredRows: CGFloat, desiredCols: CGFloat) -> CGSize {
        // TODO: Add different config for landscape mode, or disable the latter.
        return CGSize(
            width: floor(collectionFrame.size.width / desiredCols - (desiredCols + 1)/desiredCols * LibraryCollection.gridGapSize),
            height: floor(collectionFrame.size.height / desiredRows - (desiredRows + 1)/desiredRows * LibraryCollection.gridGapSize)
        )
    }
        
    static func numberOfItems(section: Int) -> Int {
        if let userData = State.instance.userData {
            return userData.collections.count
        } else {
            return 0
        }
    }
    
    static func createCellFor(collectionView: UICollectionView, indexPath: IndexPath) -> CollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: K.collections.library.cell.type, for: indexPath) as! CollectionViewCell
        
        cell.configure(backgroundColor: K.brand.colors.gray)
        cell.configure(collectionName: State.instance.userData!.collections[indexPath.row].name)
        return cell
    }
}
