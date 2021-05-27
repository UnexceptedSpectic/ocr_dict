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
    
    struct firestore {
        
        // Define firestore collections
        struct collections {
            struct dictionaries {
                static let value = "dictionaries"
                static let oxford = "oxford"
            }
            static let users = "users"
        }
                
    }
    
    struct dictionaries {
        
        struct oxford {
            
            struct definition {
                
                struct type {
                    static let primary = "primary"
                    static let secondary = "secondary"
                }
            }
        }
    }
    
    struct stringAttributes {
        
        static let heading1 = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24), NSAttributedString.Key.foregroundColor: UIColor.label]
        static let italicSecondaryHeading1 = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
        static let heading2 = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.label]
        static let primary14 = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label]
        static let boldPrimary14 = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.label]
        static let secondary14 = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
        static let italicSecondary14 = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
        static let italicTertiary14 = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.tertiaryLabel]
    }
    
    struct tables {
        
        struct collection {
            
            struct cell {
                
                struct nib {
                    
                    static let wordSummary = "wordSummary"
                }
            }
        }
        
        struct dictionary {
            
            struct cell {
                
                struct nib {
                    
                    static let wordPronounciation = "wordPronounciation"
                    static let category = "category"
                    static let primaryDefinition = "primaryDefinition"
                    static let secondaryDefenition = "secondaryDefenition"
                    static let origin = "origin"
                    static let noResult = "noResult"
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
