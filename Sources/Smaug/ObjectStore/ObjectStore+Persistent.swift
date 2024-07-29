//
//  ObjectStore+Mergeable.swift
//  Smaug
//
//  Created by Guido Kühn on 29.07.24.
//


import Foundation
import Observation

extension ObjectStore: Persistent {
    func encode(into container: inout EncodingContainer) throws {
        try mirror(for: PersistentProperty.self)
            .forEach { (label: String, value: PersistentProperty) in
                try value.encode(into: &container, key: PersistentCodingKey(key: label))
            }
    }

    func decode(from container: DecodingContainer) throws {
        try mirror(for: PersistentProperty.self)
            .forEach { (label: String, value: PersistentProperty) in
                try value.decode(from: container, key: PersistentCodingKey(key: label))
            }
    }
}