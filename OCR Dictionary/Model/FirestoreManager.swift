//
//  FirestoreManager.swift
//  OCR Dictionary
//
//  Created by Philip on 3/27/21.
//  Copyright © 2021 Philip Badzuh. All rights reserved.
//

import Foundation
import Firebase

protocol FirestoreWordDataDelegate {
    
    func didGetWordData(wordData: OxfordWordData?)
    
}

protocol FirestoreWordsDataDelegate {
    
    func didGetWordsData(wordsData: [OxfordWordData?])
    
}

protocol FirestoreUserDataDelegate {
    
    func didGetUserData(userData: FirestoreUserData?)
    
}

// Responsible for interacting with the firestore and manipulating response data
struct FirestoreManager {
    
    let db = Firestore.firestore()
    
    var wordDataDelegate: FirestoreWordDataDelegate?
    var wordsDataDelegate: FirestoreWordsDataDelegate?
    var userDataDelegate: FirestoreUserDataDelegate?
    
    func getWordInFirstCollection(for word: String, in userData: FirestoreUserData) -> Word? {
        // Get the indexes of starred table cells for a particular word
        let collectionsWithWord = userData.collections
            .filter({$0.words
                .filter({$0.word == word}).count > 0})
        
        // Get the indexes of starred table cells from the first collection in which the word is found. This assumes that if any word is saved in more than one collections, its starredCellIndex data is synced/consistent.
        if (collectionsWithWord.count > 0) {
            return collectionsWithWord[0].words.filter({$0.word == word})[0]
        } else {
            return nil
        }
    }
    
    func getDefinition(wordData: OxfordWordData, definitionIndex: Int) -> String {
        var definitionCounter = 0
        if let senses = wordData.results![0].lexicalEntries![0].entries![0].senses {
            for sense in senses {
                if let definitions = sense.definitions {
                    for primaryDefinition in definitions {
                        if definitionCounter == definitionIndex {
                            return primaryDefinition
                        } else {
                            definitionCounter += 1
                        }
                    }
                }
                if let subsenses = sense.subsenses {
                    for subsense in subsenses {
                        if let definitions = subsense.definitions {
                            for subDefinition in definitions {
                                if definitionCounter == definitionIndex {
                                    return subDefinition
                                } else {
                                    definitionCounter += 1
                                }
                            }
                        }
                    }
                }
            }
        }
        return "No default definition found."
    }
        
    func getWordData(for word: String) {
        
        db.collection(K.firestore.collections.dictionaries.oxford).document(word).getDocument { (querySnapshot, error) in
            if let err = error {
                print("Error getting word data: \(err)")
            } else {

                if let data = querySnapshot!.data() {
                    self.wordDataDelegate?.didGetWordData(
                        wordData: parseDict(
                            dictData: data,
                            dataModel: OxfordWordData.self))
                } else {
                    self.wordDataDelegate?.didGetWordData(wordData: nil)
                }
                
            }
        }
    }
    
    func getWordsData(for words: [Word]) {
        
        if words.count > 0 {
            let wordStrings = words.map({$0.word})
            db.collection(K.firestore.collections.dictionaries.oxford).whereField(FieldPath.documentID(), in: wordStrings).getDocuments { (querySnapshot, error) in
                if let err = error {
                    print("Error getting data for words: \(err)")
                } else {
                    var wordsData: [OxfordWordData?] = []
                    for doc in querySnapshot!.documents {
                        wordsData.append(parseDict(dictData: doc.data(), dataModel: OxfordWordData.self))
                    }
                    self.wordsDataDelegate?.didGetWordsData(wordsData: wordsData)
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
    
    func saveUserData(updatedUserData: FirestoreUserData) {
        if let currentUser = Auth.auth().currentUser {
            let updatedUserDataDict = structToDict(structInstance: updatedUserData)
            self.db.collection(K.firestore.collections.users).document(currentUser.email!).setData(updatedUserDataDict!)
        }
    }
        
    func saveUserData(add word: String, to collectionName: String, usingTemplate dbUserData: FirestoreUserData?, newStarredCellIndexes starredCellIndexes: [Int], newDefaultDefinitionIndex: Int?) -> FirestoreUserData {
        
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
            
            // Adding word to collection
            if collectionsWithWord.count == 0 {
                var didUpdate = false
                for collec in collectionsWithoutWord {
                    var c = collec
                    // If collection with target name exists, update it
                    if collec.name == collectionName {
                        // Update collection
                        c = Collection(
                            name: collec.name,
                            dateCreated: collec.dateCreated,
                            dateModified: now,
                            words: collec.words + [Word(
                                word: word,
                                dateAdded: now,
                                dateModified: now,
                                starredCellIndexes: starredCellIndexes,
                                defaultDefinitionIndex: newDefaultDefinitionIndex)]
                        )
                        didUpdate = true
                    }
                    updatedCollections.append(c)
                }
                if !didUpdate {
                    // No collection with the target name exists. Create the collection
                    let newCollec = Collection(
                        name: collectionName,
                        dateCreated: now,
                        dateModified: now,
                        words: [Word(
                            word: word,
                            dateAdded: now,
                            dateModified: now,
                            starredCellIndexes: starredCellIndexes,
                            defaultDefinitionIndex: newDefaultDefinitionIndex)]
                    )
                    updatedCollections.append(newCollec)
                }
            } else {
                // Modify all collections containing word
                var modifiedCollectionsWithWord: [Collection] = []
                for collec in collectionsWithWord {
                    let originalWordEntry = collec.words.filter({$0.word == word})[0]
                    let updatedWords = collec.words.filter({$0.word != word}) + [Word(word: word, dateAdded: originalWordEntry.dateAdded, dateModified: now, starredCellIndexes: starredCellIndexes, defaultDefinitionIndex: newDefaultDefinitionIndex)]
                    let updatedCollection = Collection(name: collec.name, dateCreated: collec.dateCreated, dateModified: now, words: updatedWords)
                    modifiedCollectionsWithWord.append(updatedCollection)
                }
                updatedCollections = collectionsWithoutWord + modifiedCollectionsWithWord
            }
            // Update user data
            updatedUserData = FirestoreUserData(collections: updatedCollections)
                
            } else {
            // Initialize user data
            updatedUserData = FirestoreUserData(collections: [Collection(name: collectionName, dateCreated: now, dateModified: now, words: [Word(word: word, dateAdded: now, dateModified: now, starredCellIndexes: starredCellIndexes, defaultDefinitionIndex: newDefaultDefinitionIndex)])])
        }
        
        let updatedUserDataDict = structToDict(structInstance: updatedUserData)

        if let currentUser = Auth.auth().currentUser {
            self.db.collection(K.firestore.collections.users).document(currentUser.email!).setData(updatedUserDataDict!)
        }
        
        return updatedUserData
    }
        
    }
