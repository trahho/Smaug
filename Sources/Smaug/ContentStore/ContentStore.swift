//
//  ContentStore.swift
//
//
//  Created by Guido Kühn on 24.12.23.
//

import Foundation

open class ContentStore: Persistent, Serializable, ContentContainer, ObservableObject, Reflectable {
    // MARK: - Types

    public typealias PersistentValue = Codable & Equatable

    public internal(set) var document: DatabaseDocument!
    {
        didSet {
            print ("Document set for \(self.typeName)")
        }
    }

    // MARK: - Enclosing

    public var objectDidChange: ObjectDidChangePublisher = .init()

    // MARK: - Initialisation

    public required init() {}

    // MARK: - Persistence

    func willChange() {
        objectWillChange.send()
    }

    func didChange() {
        objectDidChange.send()
    }

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

extension DatabaseDocument {
    @propertyWrapper
    final class Projected<Value> {
        var keyPath: ReferenceWritableKeyPath<ContentStore, Value>

        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value {
            get { fatalError() }
            set { fatalError() }
        }

        init(_ keyPath: ReferenceWritableKeyPath<ContentStore, Value>) {
            self.keyPath = keyPath
        }

        public static subscript<Enclosing: ContentStore>(_enclosingInstance instance: Enclosing,
                                                         wrapped _: ReferenceWritableKeyPath<Enclosing, Value>,
                                                         storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Projected>) -> Value
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                return instance[keyPath: storage.keyPath]
            }
            set {
                let storage = instance[keyPath: storageKeyPath]
                instance[keyPath: storage.keyPath] = newValue
            }
        }
    }
}
