//
//  ContentStore.swift
//
//
//  Created by Guido Kühn on 24.12.23.
//

import Foundation
import Observation

open class PropertyStore: PersistentContent, ContentContainer, ObservationInstance, Reflectable {

    // MARK: - Types

    public typealias PersistentValue = Codable & Equatable

    public internal(set) var document: DatabaseDocument! {
        didSet {
            print("Document set for \(typeName)")
        }
    }

    // MARK: - Enclosing

    public var objectDidChange: ObjectDidChangePublisher = .init()
    public let observationRegistrar = ObservationRegistrar()

    public func didChange() {
        objectDidChange.send()
    }
    
    // MARK: - Initialisation

    public required init() {}

    // MARK: - Access

    public subscript<T>(_ type: T.Type, _ id: T.ID) -> T? where T: ObjectStore.Object {
        document[type, id]
    }

    public subscript<T>(_ type: T.Type) -> Set<T> where T: ObjectStore.Object {
        document[type]
    }

    public func add<T>(_ item: T) where T: ObjectStore.Object {
        document.add(item)
    }

    public func create<T>(_: T.Type) -> T where T: ObjectStore.Object {
        let object = T()
        add(object)
        return object
    }

    public subscript<T>(_ type: T.Type, _ name: String) -> T where T: DatabaseDocument {
        document[type, name]
    }
}

extension PropertyStore: Persistent {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PersistentCodingKey.self)

        try mirror(for: PersistentProperty.self)
            .forEach { (label: String, value: PersistentProperty) in
                try value.encode(into: &container, key: PersistentCodingKey(key: label))
            }
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PersistentCodingKey.self)

        try mirror(for: PersistentProperty.self)
            .forEach { (label: String, value: PersistentProperty) in
                try value.decode(from: container, key: PersistentCodingKey(key: label))
            }
    }
}

// extension DatabaseDocument {
//    @propertyWrapper
//    final class Projected<Value> {
//        var keyPath: ReferenceWritableKeyPath<PropertyStore, Value>
//
//        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
//        public var wrappedValue: Value {
//            get { fatalError() }
//            set { fatalError() }
//        }
//
//        init(_ keyPath: ReferenceWritableKeyPath<PropertyStore, Value>) {
//            self.keyPath = keyPath
//        }
//
//        public static subscript<Enclosing: PropertyStore>(_enclosingInstance instance: Enclosing,
//                                                         wrapped _: ReferenceWritableKeyPath<Enclosing, Value>,
//                                                         storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Projected>) -> Value
//        {
//            get {
//                let storage = instance[keyPath: storageKeyPath]
//                return instance[keyPath: storage.keyPath]
//            }
//            set {
//                let storage = instance[keyPath: storageKeyPath]
//                instance[keyPath: storage.keyPath] = newValue
//            }
//        }
//    }
// }
