//
//  State.swift
//  OCR Dictionary
//
//  Created by Philip on 8/6/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import Foundation

// Define singleton for managing application state
class State {
    static let instance = State()
    
    // Globally available data
    var userData: FirestoreUserData?
    var userDataUpdateDelegates: [UserDataUpdateDelegate] = []
    
    private init() {}
}

// Define delegate methods for handling state change
protocol UserDataUpdateDelegate {
  func updateViews()
}
