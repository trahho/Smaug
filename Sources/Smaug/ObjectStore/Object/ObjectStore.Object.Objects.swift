//
//  Database.Object.Object.swift
//  Hippocampus
//
//  Created by Guido Kühn on 30.04.23.
//

import Combine
import Foundation

public extension ObjectStore.Object {
    @propertyWrapper final class Objects<Value>: ReferenceStorage where Value: ObjectStore.Object {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: [Value] {
            get { fatalError() }
            set { fatalError() }
        }

        private var cancellable: AnyCancellable?

        private var _ids: [Value.ID]?
        private var _value: [Value]?
        private var changed: Date?

        var value: [Value] {
            get {
                if let _value { return _value }
                guard
                    let database = instance.store?.document,
                    let ids = _ids
                else { return [] }

                _value = ids.compactMap { database[Value.self, $0] }
                return _value!
            }
            set {
                guard !instance.readOnly, value != newValue else { return }
                _ids = newValue.map { $0.id }
                _value = newValue
            }
        }

        private weak var _instance: ObjectStore.Object?
        private var instance: ObjectStore.Object {
            get { _instance! }
            set {
                guard newValue != _instance else { return }
                _instance = newValue
//                cancellable = _instance!.objectWillChange.sink { [self] in
//                    if instance.store?.document != nil {
//                        _value = nil
//                    }
//                }
            }
        }

        override func adopt(document: DatabaseDocument) {
            if let _value { _value.forEach { document.add($0) }}
        }

      

        public static subscript<Enclosing>(_enclosingInstance instance: Enclosing,
                                                   wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, [Value]>,
                                           storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Objects>) -> [Value] where Enclosing: ObjectStore.Object
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                storage.showAccess()
                return storage.value
            }
            set {
                guard !instance.readOnly else { return }
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                try! storage.withMutation {
                    storage.value = newValue
                }
                instance.store?.objectDidChange.send()
            }
        }
    }
}


extension ObjectStore.Object.Objects: Mergeable {
    public func merge(other: Mergeable) throws {
        guard let other = other as? Self else { return }
        if let otherChanged = other.changed, otherChanged > changed ?? .distantPast {
            try withMutation {
                changed = otherChanged
                _ids = other._ids
                _value = nil
            }
        }
    }
}

extension ObjectStore.Object.Objects: PersistentProperty {
    func encode(into container: inout EncodingContainer, key: PersistentCodingKey) throws {
        guard let changed else { return }
        try container.encodeIfPresent(Coded(value: _ids ?? [], changed: changed), forKey: key)
    }

    func decode(from container: DecodingContainer, key: PersistentCodingKey) throws {
        if let coded = try? container.decodeIfPresent(Coded.self, forKey: key) {
            _ids = coded.value
            changed = coded.changed
        }
    }

    struct Coded: Codable {
        var value: [Value.ID]
        var changed: Date
    }
}
