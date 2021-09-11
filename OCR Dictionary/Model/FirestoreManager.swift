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
    
    //    func getDefinition(wordData: OxfordWordData, cellIndex: Int) -> String {
    //        var counter = 0
    //        if let results = wordData.results {
    //            for result in results {
    //                // Each result starts with a wordPronounciationCell and categoryCell cell
    //                counter += 2
    //                if let lexicalEntries = result.lexicalEntries {
    //                    for lexEntry in lexicalEntries {
    //                        // Each lexical cell has variable numbers of primDefCells and subDefCells
    //                        if let senses = lexEntry.entries![0].senses {
    //                            for sense in senses {
    //                                if let definitions = sense.definitions {
    //                                    for primaryDefinition in definitions {
    //                                        if counter == cellIndex {
    //                                            return primaryDefinition
    //                                        } else {
    //                                            counter += 1
    //                                        }
    //                                    }
    //                                }
    //                                if let subsenses = sense.subsenses {
    //                                    for subsense in subsenses {
    //                                        if let definitions = subsense.definitions {
    //                                            for subDefinition in definitions {
    //                                                if counter == cellIndex {
    //                                                    return subDefinition
    //                                                } else {
    //                                                    counter += 1
    //                                                }
    //                                            }
    //                                        }
    //                                    }
    //                                }
    //                            }
    //                        }
    //                    }
    //                }
    //                // Each result ends with an originCell
    //                counter += 1
    //            }
    //        }
    //        return "No default definition found."
    //    }
    
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
        
        struct wordData {
            let data: OxfordWordData?
            let indexInInput: Int
        }
        
        if words.count > 0 {
            let wordStrings = words.map({$0.word})
            db.collection(K.firestore.collections.dictionaries.oxford).whereField(FieldPath.documentID(), in: wordStrings).getDocuments { (querySnapshot, error) in
                if let err = error {
                    print("Error getting data for words: \(err)")
                } else {
                    var wordsData: [wordData?] = []
                    for doc in querySnapshot!.documents {
                        wordsData.append(
                            wordData(
                                data: parseDict(dictData: doc.data(), dataModel: OxfordWordData.self),
                                indexInInput: wordStrings.firstIndex(of: doc.documentID)!))
                    }
                    // Sort pulled word data to match input word order. 
                    wordsData.sort(by: {$0!.indexInInput < $1!.indexInInput})
                    self.wordsDataDelegate?.didGetWordsData(wordsData: wordsData
                                                                .map({$0!.data}))
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
                        // Initialize user data
                        let userData = FirestoreUserData(collections: [], history: [])
                        self.saveUserData(updatedUserData: userData)
                        self.userDataDelegate?.didGetUserData(userData: userData)
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
    
    func initOrUpdateUserData(add word: String, to collectionName: String, usingTemplate dbUserData: FirestoreUserData?, newStarredCellIndexes starredCellIndexes: [Int], newDefaultDefinitionIndex: Int?) -> FirestoreUserData {
        
        var updatedUserData: FirestoreUserData
        let now = getDatetimeString()
        
        if let userData = dbUserData {
            
            // Update collections
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
            
            func createCollection() -> Collection {
                return Collection(
                    name: collectionName,
                    dateCreated: now,
                    dateModified: now,
                    words: [Word(
                                word: word,
                                dateAdded: now,
                                dateModified: now,
                                starredCellIndexes: starredCellIndexes,
                                defaultDefinitionCellIndex: newDefaultDefinitionIndex)]
                )
            }
            
            func addWordToCollection(collection: Collection) -> Collection {
                return Collection(
                    name: collection.name,
                    dateCreated: collection.dateCreated,
                    dateModified: now,
                    words: collection.words + [Word(
                                                word: word,
                                                dateAdded: now,
                                                dateModified: now,
                                                starredCellIndexes: starredCellIndexes,
                                                defaultDefinitionCellIndex: newDefaultDefinitionIndex)]
                )
            }
            
            // Adding word to collection
            if collectionsWithWord.count > 0 {
                // Modify all collections containing word
                var modifiedCollectionsWithWord: [Collection] = []
                for collec in collectionsWithWord {
                    let originalWordEntry = collec.words.filter({$0.word == word})[0]
                    let updatedWord = Word(word: word, dateAdded: originalWordEntry.dateAdded, dateModified: now, starredCellIndexes: starredCellIndexes, defaultDefinitionCellIndex: newDefaultDefinitionIndex)
                    let updatedWords = [updatedWord] + collec.words.filter({$0.word != word})
                    let updatedCollection = Collection(name: collec.name, dateCreated: collec.dateCreated, dateModified: now, words: updatedWords)
                    modifiedCollectionsWithWord.append(updatedCollection)
                }
                updatedCollections = modifiedCollectionsWithWord + collectionsWithoutWord
                // Word exists in other collections, but not in new target collection
                if (collectionsWithWord.filter({ $0.name == collectionName }).count == 0) {
                    let nonTargetCollecs = updatedCollections.filter({ $0.name != collectionName })
                    let targetCollection = updatedCollections.filter({ $0.name == collectionName })
                    // Collection exists -> update it
                    if (targetCollection.count != 0) {
                        updatedCollections = [addWordToCollection(collection: targetCollection[0])] + nonTargetCollecs
                    } else {
                        // Collection doesn't exist -> create it
                        updatedCollections.insert(createCollection(), at: 0)
                    }
                }
            } else {
                // No collections with word
                var didUpdate = false
                for collec in collectionsWithoutWord {
                    var c = collec
                    // If collection with target name exists, update it
                    var prepend = false
                    if collec.name == collectionName {
                        // Update collection by adding word
                        c = addWordToCollection(collection: collec)
                        didUpdate = true
                        prepend = true
                    }
                    if prepend {
                        updatedCollections.insert(c, at: 0)
                        prepend = false
                    } else {
                        updatedCollections.append(c)
                    }
                }
                if !didUpdate {
                    // No collection with the target name exists. Create the collection
                    updatedCollections.insert(createCollection(), at: 0)
                }
            }
            // Ensure the input collection - the primary one being update/created - is the first element
            updatedCollections = updatedCollections.filter({ $0.name == collectionName }) + updatedCollections.filter({ $0.name != collectionName })
            
            // Update user data
            updatedUserData = FirestoreUserData(collections: updatedCollections, history: dbUserData!.history)
            
        } else {
            // Initialize user data
            updatedUserData = FirestoreUserData(
                collections: [Collection(
                                name: collectionName,
                                dateCreated: now,
                                dateModified: now,
                                words: [Word(
                                            word: word,
                                            dateAdded: now, dateModified: now,
                                            starredCellIndexes: starredCellIndexes,
                                            defaultDefinitionCellIndex: newDefaultDefinitionIndex)])],
                                            history: dbUserData!.history)
        }
        
        return updatedUserData
    }
    
    func deleteWordFromCollection(userData: FirestoreUserData, word: String, collectionInd: Int) -> FirestoreUserData? {
        if let currentUser = Auth.auth().currentUser {
            let updatedCollectionWords = userData.collections[collectionInd].words.filter({ $0.word != word })
            var nonTargetCollections: [Collection] = []
            var targetCollection: [Collection] = []
            userData.collections.forEach { (collec) in
                if (collec.name != userData.collections[collectionInd].name) {
                    nonTargetCollections.append(collec)
                } else {
                    targetCollection.append(Collection(name: collec.name, dateCreated: collec.dateCreated, dateModified: collec.dateModified, words: updatedCollectionWords))
                }
            }
            var updatedUserData = userData
            updatedUserData.collections = targetCollection + nonTargetCollections
            let updatedUserDataDict = structToDict(structInstance: updatedUserData)
            self.db.collection(K.firestore.collections.users).document(currentUser.email!).setData(updatedUserDataDict!)
            return updatedUserData
        }
        return nil
    }
    
}
