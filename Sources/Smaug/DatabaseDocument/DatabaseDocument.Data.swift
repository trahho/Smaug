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
    final class Data<Store>: DataStorage where Store: ObjectStore {
        // MARK: Properties

        var container: ObjectStore.Container<Store>!
        var commitOnChange: Bool
        var publishChange: Bool
        var cancellable: AnyCancellable!

        var staticContent: Store!

        // MARK: Computed Properties

        public var content: Store {
            get { container.content }
            set { container.setContent(content: newValue) }
        }

        // MARK: - Wrapping

        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Store {
            get { fatalError() }
            set { fatalError() }
        }

        public var projectedValue: Data<Store> {
            return self
        }

        // MARK: Lifecycle

        // MARK: - Initialization

        public init(publishChange: Bool = true, commitOnChange: Bool = true) {
            self.commitOnChange = commitOnChange
            self.publishChange = publishChange
        }

        // MARK: Overridden Functions

        override func setup(url: URL, name: String, document: DatabaseDocument) {
            self.document = document
            staticContent = Store()
            staticContent.document = document
            let url = url.appending(component: name + ".data")
            container = ObjectStore.Container(document: document, url: url, content: Store(), commitOnChange: commitOnChange)
//            if publishChange {
//                cancellable = container!.objectWillChange.sink { document.objectWillChange.send() }
//            }
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

//        override func deleteObject<Result>(_ object: Result) where T: ObjectStore.Object {
//            guard !document.inSetup else {                throw Failure.deletedWhileSetup            }
//        }

        override func deleteObject<T>(item: T) throws where T: ObjectStore.Object {
            guard try content.getObject(type: T.self, id: item.id) != nil else {
                return
            }
            try withMutation {
                try content.deleteObject(item: item)
            }
        }

        override func removeReferences<T>(to item: T) where T: ObjectStore.Object {
            content.removeReferences(to: item)
        }

        override func getObject<Result>(type: Result.Type, id: Result.ID) throws -> Result? where Result: ObjectStore.Object {
            guard let result = try content.getObject(type: type, id: id) else {
                showAccess()
                return try staticContent.getObject(type: type, id: id)
            }
            showAccess()
            return result
        }

        override func getObjects<Result>(type: Result.Type) throws -> Set<Result> where Result: ObjectStore.Object {
            let staticObjects = try staticContent.getObjects(type: type)
            let dynamicObjects = try content.getObjects(type: type)
            showAccess()
            return staticObjects.union(dynamicObjects)
        }

        override func addObject<Result>(item: Result) throws where Result: ObjectStore.Object {
            guard !document.inSetup else {
                try staticContent.addObject(item: item)
                item.isLocked = true
                item.isStatic = true
//                print("Static added \(T.self)")
                return
            }
            try withMutation {
                try content.addObject(item: item)
            }
//            print("Persistent added \(T.self)")
        }

        // MARK: Static Functions

        public static subscript<Enclosing: DatabaseDocument>(_enclosingInstance instance: Enclosing,
                                                             wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Store>,
                                                             storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Data>) -> Store
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                storage.showAccess()
                return storage.content
            }
            set {}
        }

        // MARK: Functions

        public func addStaticObject<Result>(item: Result) throws where Result: ObjectStore.Object {
            try withMutation {
                try staticContent.addObject(item: item)
                item.isLocked = true
                item.isStatic = true
            }
        }

        public func makeObjectStatic<Result>(item: Result) throws where Result: ObjectStore.Object {
            guard let dynamicItem = try content.getObject(type: Result.self, id: item.id), dynamicItem == item else { return }
            try content.removeObject(item: dynamicItem)
            item.isLocked = true
            item.isStatic = true
            try staticContent.addObject(item: item)
        }
    }
}
