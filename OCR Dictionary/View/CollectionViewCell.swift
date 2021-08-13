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
    
    // Custom config for cell
    override func layoutSubviews() {
        super.layoutSubviews()
        // Round corners
        self.layer.cornerRadius = 10.0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    public func configure(backgroundColor color: UIColor) {
        imageView.backgroundColor = color
    }
    
    public func getBackgroundColor() -> UIColor? {
        return imageView.backgroundColor
    }
    
    public func configure(collectionName title: String) {
        titleLabel.text = title
    }

    // Associate cell with template file
    static func nib(nibName: String) -> UINib {
        return UINib(nibName: nibName, bundle: nil)
    }
    
}
