//
//  File.swift
//
//
//  Created by Guido Kühn on 06.05.23.
//

import Foundation

public extension ObjectStore.Object {
    class PropertyStorage {
        var withMutation: ((() throws -> ()) throws -> ()) = { action in try action() }
        var showAccess: (() -> ()) = {}

        func configureObservation<Enclosing, T>(instance: Enclosing, keyPath: ReferenceWritableKeyPath<Enclosing, T>) where Enclosing: ObjectStore.Object {
            withMutation = { action in
                instance.objectWillChange.send()
                try instance._$observationRegistrar.withMutation(of: instance, keyPath: keyPath, action)
                instance.store?.objectDidChange.send()
            }
            showAccess = {
                instance._$observationRegistrar.access(instance, keyPath: keyPath)
            }
        }

        public init() {}
    }

    class ReferenceStorage: PropertyStorage {
        func adopt(document _: DatabaseDocument) {}
    }
}
