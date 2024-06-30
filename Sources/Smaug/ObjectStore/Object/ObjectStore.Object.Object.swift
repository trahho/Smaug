//
//  Database.Relation.swift
//  Hippocampus
//
//  Created by Guido Kühn on 29.04.23.
//

import Combine
import Foundation

public extension ObjectStore.Object {
    @propertyWrapper final class Object<Value>: ReferenceStorage where Value: ObjectStore.Object {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value? {
            get { fatalError() }
            set { fatalError() }
        }

        private var cancellable: AnyCancellable?

        private var _id: Value.ID?
        private var _value: Value?
        private var changed: Date?
        private var resetRelation: (() -> Void)?
        private var deleteReference: Bool

        public init(deleteReference: Bool = false) {
            self.deleteReference = deleteReference
        }
        
        override func deleteRelations() {
            guard deleteReference, let value else { return }
            value.delete()
        }

        private weak var _instance: ObjectStore.Object?

        var value: Value? {
            get {
                if let _value { return _value }
                guard
                    let document = instance.store?.document,
                    let id = _id,
                    let value = document[Value.self, id]
                else { return nil }

                _value = value
                return _value
            }
            set {
                guard !instance.readOnly, value != newValue else { return }
                _id = newValue?.id
                _value = newValue
                changed = instance.writingTimestamp
                if let document = instance.store?.document, let newValue {
                    document.add(newValue)
                }
            }
        }

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
            if let _value { document.add(_value) }
        }

        public static subscript<Enclosing>(_enclosingInstance instance: Enclosing,
                                           wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Value?>,
                                           storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Object>) -> Value? where Enclosing: ObjectStore.Object
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                storage.resetRelation = { storage.resetRelations(keyPath: wrappedKeyPath) }
                storage.showAccess()
                return storage.value
            }
            set {
                guard !instance.readOnly else { return }
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                storage.resetRelation = { storage.resetRelations(keyPath: wrappedKeyPath) }
                try! storage.withMutation {
                    storage.resetRelation?()
                    storage.value = newValue
                    storage.changed = instance.writingTimestamp
                    storage.resetRelation?()
                }
                instance.store?.didChange()
            }
        }

        func resetRelations<Enclosing>(keyPath: KeyPath<Enclosing, Value?>) where Enclosing: ObjectStore.Object {
            guard let value else { return }
            value.mirror(for: Relation<Value, Enclosing>.self)
                .filter { $0.value.objectKeyPath == keyPath }
                .forEach {
                    $0.value.resetValue()
                }
            value.mirror(for: Relations<Value, Enclosing>.self)
                .filter { $0.value.objectKeyPath == keyPath }
                .forEach {
                    $0.value.resetValue()
                }
        }
    }
}

extension ObjectStore.Object.Object: MergeablePropertyWrapper {
    public func merge(other: Mergeable) throws {
        guard let other = other as? Self else { return }
        if let otherChanged = other.changed, otherChanged > changed ?? .distantPast {
            try withMutation {
                changed = otherChanged
                resetRelation?()
                _id = other._id
                _value = nil
                resetRelation?()
            }
        }
    }
}

extension ObjectStore.Object.Object: PersistentProperty {
    func encode(into container: inout EncodingContainer, key: PersistentCodingKey) throws {
        guard let changed else { return }
        try container.encodeIfPresent(Coded(value: _id, changed: changed), forKey: key)
    }

    func decode(from container: DecodingContainer, key: PersistentCodingKey) throws {
        if let coded = try? container.decodeIfPresent(Coded.self, forKey: key) {
            _id = coded.value
            changed = coded.changed
        }
    }

    struct Coded: Codable {
        var value: Value.ID?
        var changed: Date
    }
}
