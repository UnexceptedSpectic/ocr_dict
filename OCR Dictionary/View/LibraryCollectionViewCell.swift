//
//  CollectionViewCell.swift
//  OCR Dictionary
//
//  Created by Philip on 6/8/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit

class LibraryCollectionViewCell: UICollectionViewCell {
    
    // Configure library collection view cell based on user input
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    static let identifier = "LibraryCollectionViewCell"
    static let backgroundColors = [
        "default": UIColor.lightGray,
        "green": UIColor.green,
        "blue": UIColor.blue,
        "cyan": UIColor.cyan]

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    public func configure(backgroundColor color: UIColor) {
        imageView.backgroundColor = color
    }
    
    public func configure(projectName title: String) {
        titleLabel.text = title
    }

    // Associate cell with template file
    static func nib() -> UINib {
        return UINib(nibName: LibraryCollectionViewCell.identifier, bundle: nil)
    }
    
}
