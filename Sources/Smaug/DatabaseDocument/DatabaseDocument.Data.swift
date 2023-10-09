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
    final class Data<T>: DataStorage where T: ObjectStore {
        // MARK: - Initialization

        public init(publishChange: Bool = true, commitOnChange: Bool = true) {
            self.commitOnChange = commitOnChange
            self.publishChange = publishChange
        }

        // MARK: - Content

        var container: ObjectStoreContainer<T>!
        var commitOnChange: Bool
        var publishChange: Bool
        var cancellable: AnyCancellable!

        var staticContent: T!
        public var content: T {
            get { container.content }
            set { container.setContent(content: newValue) }
        }

        override func setup(url: URL, name: String, document: DatabaseDocument) {
            self.document = document
            staticContent = T()
            staticContent.document = document
            let url = url.appending(component: name + ".data")
            container = ObjectStoreContainer(document: document, url: url, content: T(), commitOnChange: commitOnChange)
            if publishChange {
                cancellable = container!.objectWillChange.sink { document.objectWillChange.send() }
            }
        }

        override func start() {
            container.start()
        }

        override func load() {
            container.load()
        }

        override func save() {
            container.save()
        }

        // MARK: - Storage

        override func getObject<Result>(type: Result.Type, id: Result.ID) throws -> Result? where Result: ObjectStore.Object {
            guard let result = try content.getObject(type: type, id: id) else {
                return try staticContent.getObject(type: type, id: id)
            }
            return result
        }

        override func getObjects<Result>(type: Result.Type) throws -> Set<Result> where Result: ObjectStore.Object {
            let staticObjects = try staticContent.getObjects(type: type)
            let dynamicObjects = try content.getObjects(type: type)
            return staticObjects.union(dynamicObjects)
        }

        override func addObject<Result>(item: Result) throws where Result: ObjectStore.Object {
            guard !document.inSetup else {
                try staticContent.addObject(item: item)
                item.isStatic = true
//                print("Static added \(T.self)")
                return
            }
            try content.addObject(item: item)
            print("Persistent added \(T.self)")
        }

        // MARK: - Wrapping

        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: T {
            get { fatalError() }
            set { fatalError() }
        }

        public static subscript<Enclosing: DatabaseDocument>(_enclosingInstance instance: Enclosing,
                                                             wrapped _: ReferenceWritableKeyPath<Enclosing, T>,
                                                             storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Data>) -> T
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                return storage.content
            }
            set {}
        }

        public var projectedValue: Data<T> {
            return self
        }
    }
}
