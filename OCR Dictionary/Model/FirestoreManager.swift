//
//  FirestoreManager.swift
//  OCR Dictionary
//
//  Created by Philip on 3/27/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import Foundation
import Firebase

protocol FirestoreUserWordCellsDelegate {
    
    func didGetWordData(wordData: OxfordWordData?)
    
}

protocol FirestoreUserDataDelegate {
    
    func didGetUserData(userData: FirestoreUserData?)
    
}

// Responsible for interacting with the firestore and manipulating response data
struct FirestoreManager {
    
    let db = Firestore.firestore()
    
    var wordCellsDelegate: FirestoreUserWordCellsDelegate?
    var userDataDelegate: FirestoreUserDataDelegate?
    
    func getStarredCellIndexes(for word: String, in userData: FirestoreUserData) -> [Int]? {
        // Get the indexes of starred table cells for a particular word
        let collectionsWithWord = userData.collections
            .filter({$0.words
                .filter({$0.word == word}).count > 0})
        
        // Get the indexes of starred table cells from the first collection in which the word is found. This assumes that if any word is saved in more than one collections, its starredCellIndex data is synced/consistent.
        if (collectionsWithWord.count > 0) {
            return collectionsWithWord[0].words.filter({$0.word == word})[0].starredCellIndexes
        } else {
            return nil
        }
    }
        
    func getWordData(for word: String) {
        
        db.collection(K.firestore.collections.dictionaries.oxford).document(word).getDocument { (querySnapshot, error) in
            if let err = error {
                print("Error getting word data: \(err)")
            } else {

                if let data = querySnapshot!.data() {
                    self.wordCellsDelegate?.didGetWordData(
                        wordData: parseDict(
                            dictData: data,
                            dataModel: OxfordWordData.self))
                } else {
                    self.wordCellsDelegate?.didGetWordData(wordData: nil)
                }
                
            }
        }
    }
    
    func saveWordData(for word: String, wordData: OxfordWordData) {
        
        let wordDataDict = structToDict(structInstance: wordData)
        
        self.db.collection(K.firestore.collections.dictionaries.oxford).document(word).setData(wordDataDict!) { (error) in
            if let err = error {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
    
    func getUserData() {
        // Get user data
        if let currentUser = Auth.auth().currentUser {
            self.db.collection(K.firestore.collections.users).document(currentUser.email!).getDocument { (querySnapshot, error) in
                if let err = error {
                    print("Error getting user data: \(err)")
                } else {

                    if let data = querySnapshot!.data() {
                        self.userDataDelegate?.didGetUserData(
                            userData: parseDict(
                                dictData: data,
                                dataModel: FirestoreUserData.self))
                    } else {
                        self.userDataDelegate?.didGetUserData(userData: nil)
                    }
                    
                }
            }
        } else {
            print("Error: could not get current user.")
        }
    }
        
    func saveUserData(add word: String, to collectionName: String, usingTemplate dbUserData: FirestoreUserData?, givenNew starredCellIndexes: [Int]) -> FirestoreUserData {
        
        var updatedUserData: FirestoreUserData
        let now = getDatetimeString()
        
        if let userData = dbUserData {
            
            var updatedCollections: [Collection] = []
            
            // Find all collections that contain the given word
            let collectionsWithWord = userData.collections
                .filter({$0.words
                    .filter({$0.word == word})
                    .count > 0
            })
            
            let collectionsWithoutWord = userData.collections
                .filter({$0.words
                    .filter({$0.word != word})
                    .count == $0.words.count
            })
            
            if collectionsWithWord.count == 0 {
                // Create collection
                updatedCollections = collectionsWithoutWord + [Collection(name: collectionName, dateCreated: now, dateModified: now, words: [Word(word: word, dateAdded: now, dateModified: now, starredCellIndexes: starredCellIndexes)])]
            } else {
                // Modify all collections containing word
                for collec in collectionsWithWord {
                    let originalWordEntry = collec.words.filter({$0.word == word})[0]
                    let updatedWords = collec.words.filter({$0.word != word}) + [Word(word: word, dateAdded: originalWordEntry.dateAdded, dateModified: now, starredCellIndexes: starredCellIndexes)]
                    let updatedCollection = Collection(name: collec.name, dateCreated: collec.dateCreated, dateModified: now, words: updatedWords)
                    updatedCollections.append(updatedCollection)
                }
            }
            // Update user data
            let untouchedCollections = userData.collections.filter({$0.name != collectionName})
            updatedUserData = FirestoreUserData(collections: untouchedCollections + updatedCollections)
                
            } else {
            // Initialize user data
            updatedUserData = FirestoreUserData(collections: [Collection(name: collectionName, dateCreated: now, dateModified: now, words: [Word(word: word, dateAdded: now, dateModified: now, starredCellIndexes: starredCellIndexes)])])
        }
        
        let updatedUserDataDict = structToDict(structInstance: updatedUserData)

        if let currentUser = Auth.auth().currentUser {
            self.db.collection(K.firestore.collections.users).document(currentUser.email!).setData(updatedUserDataDict!)
        }
        
        return updatedUserData
    }
    
    func getDatetimeString() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return df.string(from: Date())
    }
        
    }
