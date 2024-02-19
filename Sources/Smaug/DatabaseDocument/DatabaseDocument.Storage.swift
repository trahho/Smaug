//
//  DatabaseDocument.Storage.swift
//  Hippocampus
//
//  Created by Guido Kühn on 03.05.23.
//

import Foundation

public extension DatabaseDocument {
    class Storage {
        var document: DatabaseDocument!
        var withMutation: ((() throws -> ()) throws -> ()) = { action in try action() }
        var showAccess: (() -> ()) = {}

        func configureObservation<Enclosing, T>(instance: Enclosing, keyPath: ReferenceWritableKeyPath<Enclosing, T>) where Enclosing: DatabaseDocument {
            withMutation = { action in
                instance.objectWillChange.send()
                try instance._$observationRegistrar.withMutation(of: instance, keyPath: keyPath, action)
            }
            showAccess = {
                instance._$observationRegistrar.access(instance, keyPath: keyPath)
            }
        }

        func setup(url: URL, name: String, document: DatabaseDocument) {}
        func load() {}
        func save() {}
        func start() {}
    }
}
