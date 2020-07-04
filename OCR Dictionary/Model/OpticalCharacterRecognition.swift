//
//  OpticalCharacterRecognition.swift
//  OCR Dictionary
//
//  Created by Philip on 6/22/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import Foundation
import TesseractOCR

class OpticalCharacterRecognition {
    
    var tesseract: G8Tesseract
    
    init(lang: String) {
        
        // 'lang' is defined by the filename prefix in tessdata
        // 'lang' can be defined as a comination of languages e.g. as 'eng+fra'
        
        tesseract = G8Tesseract(language: lang)!
        tesseract.engineMode = .tesseractCubeCombined
        tesseract.pageSegmentationMode = .auto
        
    }
    
    public func getText(with image: UIImage) -> String {
        
        tesseract.image = image
        tesseract.recognize()
        return tesseract.recognizedText!
        
    }
    
}
