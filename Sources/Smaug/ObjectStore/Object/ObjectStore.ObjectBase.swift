//
//  File.swift
//  
//
//  Created by Guido Kühn on 10.06.24.
//

import Foundation

extension ObjectStore {
    open class ObjectBase: Identifiable, Hashable, Reflectable, Mergeable, ObservationInstance, Persistent {
        public typealias ID = UUID

        public internal(set) var id: ID = UUID()

        public let observationRegistrar = Observation.ObservationRegistrar()

        public static func == (lhs: ObjectStore.ObjectBase, rhs: ObjectStore.ObjectBase) -> Bool {
            lhs.id == rhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        public required init() {}

        public init(id: ID) {
            self.id = id
        }

        open func merge(other: Mergeable) throws {
            guard let other = other as? Self, other.id == id else { return }

            for  (own, other) in zip(mirror(for: MergeablePropertyWrapper.self), other.mirror(for: MergeablePropertyWrapper.self)) {
                var value = own.value
                try value.merge(other: other.value)
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: PersistentCodingKey.self)

            try container.encode(id, forKey: PersistentCodingKey(key: "ID"))

            try mirror(for: PersistentProperty.self)
                .forEach { (label: String, value: PersistentProperty) in
                    try value.encode(into: &container, key: PersistentCodingKey(key: label))
                }
        }

        public func decode(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: PersistentCodingKey.self)

            try id = container.decode(ID.self, forKey: PersistentCodingKey(key: "ID"))

            try mirror(for: PersistentProperty.self)
                .forEach { (label: String, value: PersistentProperty) in
                    try value.decode(from: container, key: PersistentCodingKey(key: label))
                }
        }
    }
}
