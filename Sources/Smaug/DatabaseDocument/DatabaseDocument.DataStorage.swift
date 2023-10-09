//
//  DatabaseDocument.DataStorage.swift
//  Hippocampus
//
//  Created by Guido Kühn on 03.05.23.
//

import Foundation
public extension DatabaseDocument {
    class DataStorage: Storage {
        func getObject<T>(type: T.Type, id: T.ID) throws -> T? where T: ObjectStore.Object { fatalError("not implemented") }
        func getObjects<T>(type: T.Type) throws -> Set<T> where T: ObjectStore.Object { fatalError("not implemented") }
        func addObject<T>(item: T) throws where T: ObjectStore.Object { fatalError("not implemented") }
        
      
    }
}
