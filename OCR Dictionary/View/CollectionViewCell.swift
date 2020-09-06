//
//  CollectionViewCell.swift
//  OCR Dictionary
//
//  Created by Philip on 6/8/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    // Configure library collection view cell based on user input
    
    // CollectionViewCell outlets
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
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
    static func nib(nibName: String) -> UINib {
        return UINib(nibName: nibName, bundle: nil)
    }
    
}
