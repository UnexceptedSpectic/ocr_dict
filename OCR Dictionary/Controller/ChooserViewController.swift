//
//  CropperViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 6/3/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit

class ChooserViewController: UIViewController {

    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var resultTableView: UITableView!
    
    var capturedImage: UIImage?
    let ocr = OpticalCharacterRecognition(lang: "eng")
    var foundWords: [String] = []
    var chosenWord: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewImage.contentMode = .scaleAspectFit
        
        previewImage.addSubview(SnapperViewController.generateWordFocusBoxLabel(view: self.view))
        
        // Analyze cropped image
        let foundText = ocr.getText(with: cropImageToWordFocus(image: capturedImage!))
        // Save found words to results array
        self.foundWords = foundText.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                                    .components(separatedBy: CharacterSet.whitespacesAndNewlines)
                                    .filter { !$0.isEmpty }
        print(self.foundWords)

        // Configure the result table view
        resultTableView.register(TableViewCell.nib(nibName: TableViewCell.resultID), forCellReuseIdentifier: TableViewCell.resultID)
        resultTableView.delegate = self
        resultTableView.dataSource = self
        resultTableView.showsVerticalScrollIndicator = false
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        previewImage.image = capturedImage
        super.updateViewConstraints()
    
        // Center the result table cells vertically
        resultTableView.contentInset = UIEdgeInsets(top: max(resultTableView.frame.size.height/2 - resultTableView.contentSize.height/2, 0), left: 0, bottom: 0, right: 0)
        resultTableView.isHidden = false
        
    }
    
    @IBAction func closeView(_ sender: UIButton) {
    
        dismiss(animated: true, completion: nil)
    
    }
    
    func cropImageToWordFocus(image: UIImage) -> UIImage {

        return UIImage(cgImage: (image.cgImage?.cropping(to:
            CGRect(x: Int(image.size.width) / 2 - Int(image.size.width / 3 / 2),
                   y: Int(image.size.height) / 2 - Int(image.size.height / 12),
                   width: Int(image.size.width / 3),
                   height: Int(image.size.height / 12)))
            )!
        )
    
    }
    
    @objc func cellTapped(cellButton: UIButton) {
                
        // Attempt to define the chosen word
//        let dictVc = UIReferenceLibraryViewController(term: (cellButton.titleLabel?.text!)!)
//        self.present(dictVc, animated: true, completion: nil)
        self.chosenWord = (cellButton.titleLabel?.text!)!
        performSegue(withIdentifier: "ChooserToDict", sender: self)
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dictionaryVC = segue.destination as! DictionaryViewController
        dictionaryVC.queryWord = self.chosenWord.lowercased()
    }

}

// Extensions for the result table view
extension ChooserViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
}

extension ChooserViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.foundWords.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.resultID, for: indexPath) as! TableViewCell
        cell.resultButton.setTitle(self.foundWords[indexPath.row].trimmingCharacters(in: CharacterSet.alphanumerics.inverted), for: .normal)
        cell.resultButton.addTarget(self, action: #selector(cellTapped(cellButton:)), for: .touchUpInside)
        // TODO: allow users to edit a cell's word? select relevant portion? train model?
//        cell.resultTextField.text = self.foundWords[indexPath.row]
//        cell.resultTextField.isUserInteractionEnabled = false
        return cell
        
    }
    
}
