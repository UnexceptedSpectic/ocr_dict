//
//  Util.swift
//  OCR Dictionary
//
//  Created by Philip on 3/30/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import Foundation
import DictionaryCoding

func parseJSON<T: Decodable>(jsonData: Data, dataModel: T.Type) -> T? {
    
    let decoder = JSONDecoder()
    do {
        
        let decodedData = try decoder.decode(dataModel.self, from: jsonData)
        return decodedData
        
    } catch {
        
        print(print("Error: decoding json data failed: ", error))
        return nil
        
    }
    
}

func parseDict<T: Decodable>(dictData: Dictionary<String, Any>, dataModel: T.Type) -> T? {
    
    let decoder = DictionaryDecoder()
    do {
        let decodedData = try decoder.decode(dataModel.self, from: dictData)
        return decodedData
    } catch {
        
        print("Error: decoding dictionary data failed: ", error)
        return nil
    }
    
}

func structToDict<T: Encodable>(structInstance: T) -> Dictionary<String, Any>? {
    
    let encoder = DictionaryEncoder()
    do {
        let encodedDict = try encoder.encode(structInstance) as [String: Any]
        return encodedDict
    } catch {
        
        print("Error: encoding struct data to dictionary failed: ", error)
        return nil
    }
}

func uppercaseFirstCharacter(str: String) -> String {
    let strArray = str.map { String($0) }
    return strArray[0].uppercased() + strArray[1...(strArray.count - 1)].joined(separator: "")
}
