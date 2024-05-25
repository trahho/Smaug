//
//  DatabaseDocument.Storage.swift
//  Hippocampus
//
//  Created by Guido Kühn on 03.05.23.
//

import Foundation

public extension DatabaseDocument {
    class Storage: ObservationPropertyWrapper {
        var document: DatabaseDocument!

        func setup(url: URL, name: String, document: DatabaseDocument) {}
        func load() {}
        func save() {}
        func start() {}
    }
}
