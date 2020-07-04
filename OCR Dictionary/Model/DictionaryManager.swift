    //
    //  DictionaryManager.swift
    //  OCR Dictionary
    //
    //  Created by Philip on 7/1/20.
    //  Copyright © 2020 Philip Badzuh. All rights reserved.
    //
    
    import Foundation
    
    protocol WordDataDelegate {
        
        func didGetWordData(wordData: WordData)
        
    }
    
    // Responsible for interacting with the oxford dictionaries api and manipulating response data
    struct DictionaryManager {
        
        let app_id = "b0885c3e"
        let app_key = "50d0fd2ef009bd7dd6a3eaf8954c9ffc"
        let endpoint = "entries"
        let language_code = "en-us"
        
        var delegate: WordDataDelegate?
        
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
                        
                        if let wordData = self.parseJSON(dictData: confirmedData) {
                            // Pass data to the delegate. DictionaryViewController should declare itself as such.
                            self.delegate?.didGetWordData(wordData: wordData)
                        }
                        
                    }
                    
                }
                
                task.resume()
                
            }
                        
        }
        
        func parseJSON(dictData: Data) -> WordData? {
            
            let decoder = JSONDecoder()
            do {
                
                let decodedData = try decoder.decode(WordData.self, from: dictData)
                return decodedData
                
            } catch {
                
                print(error)
                return nil
                
            }
            
        }
    }
