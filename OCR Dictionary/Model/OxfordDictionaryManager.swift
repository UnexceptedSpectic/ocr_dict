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
    
    // Responsible for interacting with the oxford dictionaries api and manipulating response data
    struct OxfordDictionaryManager {
        
        let app_id = "b0885c3e"
        let app_key = "50d0fd2ef009bd7dd6a3eaf8954c9ffc"
        let endpoint = "entries"
        let language_code = "en-us"
        
        var delegate: OxfordWordDataDelegate?
        
        // TODO: Use the Lemmas endpoint first to link an inflected form back to its headword (e.g., pixels --> pixel).
        func getDefinitionData(word: String) {
            
            let urlString = "https://od-api.oxforddictionaries.com/api/v2/\(endpoint)/\(language_code)/\(word)"
            performRequest(for: urlString, with: ["app_id": app_id, "app_key": app_key])
            
        }
        
        func performRequest(for url: String, with headers: [String: String]) {
            
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
                        
                        if let wordData = parseJSON(jsonData: confirmedData, dataModel: OxfordWordData.self) {
                            // Pass data to the delegate. DictionaryViewController should declare itself as such.
                            self.delegate?.didGetWordData(wordData: wordData)
                        }
                        
                    }
                    
                }
                
                task.resume()
                
            }
                        
        }
        
    }
