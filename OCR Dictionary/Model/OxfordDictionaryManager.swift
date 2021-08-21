    //
    //  DictionaryManager.swift
    //  OCR Dictionary
    //
    //  Created by Philip on 7/1/20.
    //  Copyright © 2020 Philip Badzuh. All rights reserved.
    //
    
    import Foundation
    
    protocol OxfordWordDataDelegate {
        
        func didGetWordData(wordData: OxfordWordData)
    }
    
    protocol OxfordHeadwordDelegate {
        
        func didGetHeadwords(headwords: [String])
    }
    
    // Responsible for interacting with the oxford dictionaries api and manipulating response data
    struct OxfordDictionaryManager {
        
        let app_id = "b0885c3e"
        let app_key = "50d0fd2ef009bd7dd6a3eaf8954c9ffc"
        let lemmas_endpoint = "lemmas"
        let entries_endpoint = "entries"
        let language_code = "en-us"

        var headwordDelegate: OxfordHeadwordDelegate?
        var wordDataDelegate: OxfordWordDataDelegate?
        
        // Use the Lemmas endpoint to link an inflected form of a word back to its headword (e.g., pixels --> pixel).
        func getHeadword(word: String) {
            let urlString = "https://od-api.oxforddictionaries.com/api/v2/\(lemmas_endpoint)/\(language_code)/\(word)"
            performRequest(for: urlString, with: ["app_id": app_id, "app_key": app_key]) { (response) in
                if let lemmasData = parseJSON(jsonData: response, dataModel: OxfordLemmasData.self) {
                    // Pass data to the delegate. DictionaryViewController should declare itself as such.
                    var inflections: [String] = []
                    lemmasData.results?.forEach({ (lemmaResult) in
                        lemmaResult.lexicalEntries?.forEach({ inflections.append($0.inflectionOf[0].text) })
                    })
                    self.headwordDelegate?.didGetHeadwords(headwords: Array(Set(inflections)))
                }
            }
        }
        
        func getDefinitionData(word: String) {
            
            let urlString = "https://od-api.oxforddictionaries.com/api/v2/\(entries_endpoint)/\(language_code)/\(word)"
            performRequest(for: urlString, with: ["app_id": app_id, "app_key": app_key]) { (response) in
                if let wordData = parseJSON(jsonData: response, dataModel: OxfordWordData.self) {
                    // Pass data to the delegate. DictionaryViewController should declare itself as such.
                    self.wordDataDelegate?.didGetWordData(wordData: wordData)
                }
            }
            
        }
        
        func performRequest(for url: String, with headers: [String: String], dataHandler: @escaping (_ data: Data) -> Void) {
            
            if let url = URL(string: url) {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                for header in headers {
                    request.setValue(header.value, forHTTPHeaderField: header.key)
                }
                
                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    
                    if let err = error {
                        
                        print(err)
                        return
                        
                    }
                    
                    if let confirmedData = data {
                        
                        dataHandler(confirmedData)
                        
                    }
                    
                }
                
                task.resume()
                
            }
                        
        }
        
    }
