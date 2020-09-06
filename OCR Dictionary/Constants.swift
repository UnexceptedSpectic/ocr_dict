//
//  Constants.swift
//  OCR Dictionary
//
//  Created by Philip on 9/6/20.
//  Copyright © 2020 Philip Badzuh. All rights reserved.
//

import UIKit

struct K {
    
    struct collections {
        
        struct library {
            
            struct cell {
                
                static let nib = "LibraryCell"
                static let type = "library"
            }
        }
    }
    
    struct tables {
        
        struct dictionary {
            
            struct cell {
                
                struct type {
                    
                    static let name = "name"
                    static let lexical = "lexical"
                    static let origin = "origin"
                    static let noResult = "noResult"
                }
                
                struct nib {
                    
                    static let lexical = "DictLexicalCell"
                }
            }
        }
        
        struct tesseract {
            
            struct cell {
                
                struct nib {
                    
                    static let result = "TessResultCell"
                }
                
                struct type {
                    
                    static let result = "result"
                }
            }
        }
    }
    
    
    struct brand {
        
        struct fonts {
            
            static let systemDefault = "TimesNewRomanPSMT"
        }
        
        struct colors {
            
            static let gray = UIColor.lightGray
        }
    }
}
