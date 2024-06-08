//
//  File.swift
//
//
//  Created by Guido Kühn on 05.06.24.
//

import Foundation

extension ObjectPersistence {
    open class Object: Identifiable, Hashable, Reflectable, Mergeable, ObservationInstance {
        public let observationRegistrar = Observation.ObservationRegistrar()

        public typealias ID = UUID

        public internal(set) var id: ID = UUID()
        public required init() {}

        public static func == (lhs: ObjectPersistence.Object, rhs: ObjectPersistence.Object) -> Bool {
            lhs.id == rhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        open func merge(other: Mergeable) throws {
            guard let other = other as? Self, other.id == id else { return }

//            if let added, let otherAdded = other.added, otherAdded < added { self.added = other.added }

            for var (own, other) in zip(mirror(for: MergeablePropertyWrapper.self), other.mirror(for: MergeablePropertyWrapper.self)) {
                try own.value.merge(other: other.value)
            }
        }
    }
}

extension ObjectPersistence.Object: Persistent {
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
