//
//  File.swift
//
//
//  Created by Guido Kühn on 22.02.24.
//

import Foundation
public extension ObjectStore {
    class ObjectsStorageAbstract<T>: ObjectsStorage where T: Object {
        // MARK: - Key
        
        var value: Set<T> { fatalError() }
        var deletedTimestamp: Date?
        
        var withMutation: ((() throws -> ()) throws -> ()) = { action in try action() }
        var showAccess: (() -> ()) = {}
        
        func configureObservation<Enclosing>(instance: Enclosing, keyPath: ReferenceWritableKeyPath<Enclosing, Set<T>>) where Enclosing: ObjectStore {
            withMutation = { action in
                instance.objectWillChange.send()
                try instance._$observationRegistrar.withMutation(of: instance, keyPath: keyPath, action)
                instance.objectDidChange.send()
            }
            showAccess = {
                instance._$observationRegistrar.access(instance, keyPath: keyPath)
            }
        }
        
        func getObject(id: T.ID) -> T? { fatalError() }
        
        func getObjects() -> Set<T> { fatalError() }
        
        func addObject(item: T) { fatalError() }
        
        func deleteObject(item: T) { fatalError() }
    }
}
