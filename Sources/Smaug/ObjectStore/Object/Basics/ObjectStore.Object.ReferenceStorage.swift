//
//  File.swift
//
//
//  Created by Guido Kühn on 06.05.23.
//

import Foundation

public extension ObjectStore.Object {
    class ReferenceStorage: ObservationPropertyStorage {
        func adopt(document _: DatabaseDocument) {}
    }
}
