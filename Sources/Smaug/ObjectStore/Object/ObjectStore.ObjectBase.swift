//
//  File.swift
//
//
//  Created by Guido Kühn on 10.06.24.
//

import Foundation

extension ObjectStore {
    open class ObjectBase: Identifiable, Hashable, Reflectable, Mergeable, ObservationInstance, Persistent {
        // MARK: Nested Types

        public typealias ID = UUID

        // MARK: Properties

        public internal(set) var id: ID = UUID()

        public let observationRegistrar = Observation.ObservationRegistrar()

        // MARK: Lifecycle

        public required init() {}

        public init(id: ID) {
            self.id = id
        }

        // MARK: Static Functions

        public static func == (lhs: ObjectStore.ObjectBase, rhs: ObjectStore.ObjectBase) -> Bool {
            lhs.id == rhs.id
        }

        // MARK: Functions

        open func merge(other: Mergeable) throws {
            guard let other = other as? Self, other.id == id else { return }

            for (own, other) in zip(mirror(for: MergeablePropertyWrapper.self), other.mirror(for: MergeablePropertyWrapper.self)) {
                var value = own.value
                try value.merge(other: other.value)
            }
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        func encode(into container: inout EncodingContainer) throws {
            try container.encode(id, forKey: PersistentCodingKey(key: "ID"))

            try mirror(for: PersistentProperty.self)
                .forEach { (label: String, value: PersistentProperty) in
                    try value.encode(into: &container, key: PersistentCodingKey(key: label))
                }
        }

        func decode(from container: DecodingContainer) throws {
            try id = container.decode(ID.self, forKey: PersistentCodingKey(key: "ID"))

            try mirror(for: PersistentProperty.self)
                .forEach { (label: String, value: PersistentProperty) in
                    try value.decode(from: container, key: PersistentCodingKey(key: label))
                }
        }
    }
}
