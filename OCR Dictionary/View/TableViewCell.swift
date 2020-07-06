//
//  ResultTableViewCell.swift
//  OCR Dictionary
//
//  Created by Philip on 6/25/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var resultButton: UIButton!
    
    static let resultID = "ResultTableViewCell"
    
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var definitionLabel: UILabel!
    
    static let dictID = "DataForWordTypeTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // Associate cell with template file
    static func nib(nibName: String) -> UINib {
        return UINib(nibName: nibName, bundle: nil)
    }
    
}
