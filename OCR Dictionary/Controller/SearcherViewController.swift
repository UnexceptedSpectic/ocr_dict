//
//  SearcherViewController.swift
//  OCR Dictionary
//
//  Created by Philip on 8/15/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import UIKit

class SearcherViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var suggestionTable: UITableView!
    let textChecker = UITextChecker()
    var suggestions: [String]? = []
    var selectedWord: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure delegates
        self.searchBar.delegate = self
        self.suggestionTable.delegate = self
        self.suggestionTable.dataSource = self
        
        // Handle closing keyboard
        self.suggestionTable.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didTapSuggestionTable)))
        
    }
    
    @objc func didTapSuggestionTable(sender: UITapGestureRecognizer) {
        // Close keyboard on tap anywhere in suggestionTable
        if sender.state == .ended {
            self.view.endEditing(true)
        }
        sender.cancelsTouchesInView = false
    }
    
    func getSuggestions(for partial: String) -> [String]? {
        return self.textChecker.completions(
            forPartialWordRange: NSRange(0..<partial.utf16.count),
            in: partial,
            language: "en_US"
        )
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is DictionaryViewController {
            let dictVc = segue.destination as! DictionaryViewController
            dictVc.queryWord = self.selectedWord!.lowercased()
        }
    }
    
}

extension SearcherViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.suggestions = self.getSuggestions(for: searchText)
        self.suggestionTable.reloadData()
    }
}

extension SearcherViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let completions =  self.suggestions {
            return completions.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.suggestionTable.dequeueReusableCell(withIdentifier: K.tables.suggestion.cell.nib.value)!
        if let completions = self.suggestions {
            cell.textLabel?.text = completions[indexPath.row]
        }
        return cell
    }
    
}

extension SearcherViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedWord = tableView.cellForRow(at: indexPath)!.textLabel!.text
        performSegue(withIdentifier: "SearcherToDictionary", sender: self)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Close keyboard on scroll
        self.view.endEditing(true)
    }
}

extension SearcherViewController: OxfordHeadwordDelegate {
    func didGetHeadwords(headwords: [String]) {
        print(headwords)
    }
}
