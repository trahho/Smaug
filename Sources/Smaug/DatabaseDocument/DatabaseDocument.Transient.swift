//
//  DatabaseDocument.Data.swift
//  Hippocampus
//
//  Created by Guido Kühn on 30.04.23.
//

import Combine
import Foundation

public extension DatabaseDocument {
    @propertyWrapper
    final class Transient<T>: DataStorage where T: ObjectMemory {
        // MARK: - Initialization

        public init(publishChange: Bool = false) {
            self.publishChange = publishChange
        }

        // MARK: - Content

        var content: T!
        var publishChange: Bool
        var cancellable: AnyCancellable!

        override func setup(url: URL, name: String, document: DatabaseDocument) {
            self.document = document
            content = T()
            content.document = document
            if publishChange {
                cancellable = content.objectWillChange.sink { document.objectWillChange.send() }
            }
        }

        // MARK: - Storage

        override func getObject<Result>(type: Result.Type, id: Result.ID) throws -> Result? where Result: ObjectStore.Object {
            try content.getObject(type: type, id: id)
        }

        override func getObjects<Result>(type: Result.Type) throws -> Set<Result> where Result: ObjectStore.Object {
            try content.getObjects(type: type)
        }

        override func addObject<Result>(item: Result) throws where Result: ObjectStore.Object {
            try content.addObject(item: item)
        }

        // MARK: - Wrapping

        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: T {
            get { fatalError() }
            set { fatalError() }
        }

        public static subscript<Enclosing: DatabaseDocument>(_enclosingInstance instance: Enclosing,
                                                             wrapped _: ReferenceWritableKeyPath<Enclosing, T>,
                                                             storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Transient>) -> T
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                return storage.content
            }
            set {}
        }

        public var projectedValue: Transient<T> {
            return self
        }
    }
}
