//
//  DatabaseDocument.swift
//  Hippocampus
//
//  Created by Guido Kühn on 30.04.23.
//

import Foundation
import Observation

extension DatabaseDocument {
    enum Failure: Error {
        case typeNotFound
        case deletedWhileSetup
    }

    public struct Configuration {
        // MARK: Properties

        let appName: String
        let documentExtension: String

        // MARK: Lifecycle

        public init(appName: String, documentExtension: String) {
            self.appName = appName
            self.documentExtension = documentExtension
        }
    }
}

@dynamicMemberLookup
open class DatabaseDocument: Reflectable, /* ObservableObject,*/ ObservationInstance {
    // MARK: Static Computed Properties



    // MARK: Properties

    public private(set) var containerDocument: DatabaseDocument?
    public let observationRegistrar = Observation.ObservationRegistrar()
    public private(set) var url: URL

    private(set) var inSetup: Bool = false

    // MARK: - Transactional change

    private var _readingTimestamp: Date?

    private var _writingTimestamp: Date?

    // MARK: Computed Properties

    private(set) var readingTimestamp: Date! {
        get { containerDocument?.readingTimestamp ?? _readingTimestamp ?? .distantFuture }
        set {
            if let containerDocument {
                containerDocument.readingTimestamp = newValue
            } else {
                if newValue != nil, _readingTimestamp == nil {
                    _readingTimestamp = newValue
                }
                if newValue == nil, _readingTimestamp != nil {
                    _readingTimestamp = nil
                }
            }
        }
    }

    private(set) var writingTimestamp: Date! {
        get { containerDocument?.writingTimestamp ?? _writingTimestamp ?? .now }
        set {
            if let containerDocument {
                containerDocument.writingTimestamp = newValue
            } else {
                if newValue != nil, _writingTimestamp == nil {
                    _writingTimestamp = newValue
                }
                if newValue == nil, _writingTimestamp != nil {
                    _writingTimestamp = nil
                }
            }
        }
    }

    var readOnly: Bool {
        readingTimestamp < Date.distantFuture
    }

    // MARK: - Storage

    var storages: [DataStorage] {
        mirror(for: DataStorage.self).map { $0.value }
    }

    private var isActive: Bool {
        let timestamp = containerDocument?.writingTimestamp ?? _writingTimestamp
        return timestamp != nil
    }

    // MARK: Lifecycle

    // MARK: - Initialization

    public required init(url: URL, containerDocument: DatabaseDocument? = nil) {
        self.url = url
        self.containerDocument = containerDocument
        let storages = mirror(for: Storage.self)
        for storage in storages {
            storage.value.setup(url: url, name: storage.label, document: self)
        }

        inSetup = true
        setup()
        inSetup = false

        for storage in storages {
            storage.value.load()
            storage.value.start()
        }
    }
    
    public func load() {
        for storage in storages {
            storage.load()
        }
    }

    public convenience init(name: String, local: Bool, configuration: Configuration) {
        let containerURL = local ? URL.localContainerUrl.appendingPathComponent(configuration.appName) : URL.iCloudContainerUrl
        let url = containerURL.appendingPathComponent("\(name)\(configuration.documentExtension)")
        self.init(url: url)
    }

    // MARK: Functions

    open func setup() {}

    public subscript<T>(_ type: T.Type, _ id: T.ID) -> T? where T: ObjectStore.Object {
        try! getObject(type: type, id: id)
    }

    public subscript<T>(_ type: T.Type) -> Set<T> where T: ObjectStore.Object {
        try! getObjects(type: type)
    }

    public subscript<T, S>(_ type: T.Type, _ ids: S) -> Set<T> where T: ObjectStore.Object, S: Sequence, S.Element == T.ID {
        ids.compactMap { try! getObject(type: type, id: $0) }.asSet
    }

    public subscript<T>(_ type: T.Type) -> T where T: ObjectStore.Object {
        create(type)
    }

    public subscript<T>() -> T where T: ObjectStore.Object {
        get { fatalError() }
        set { add(newValue) }
    }

    public subscript<T>() -> [T] where T: ObjectStore.Object {
        get { fatalError() }
        set { newValue.forEach { add($0) } }
    }

    public func add<T>(_ item: T) where T: ObjectStore.Object {
        change {
            try! addObject(item: item)
        }
    }

    @discardableResult public func create<T>(_: T.Type) -> T where T: ObjectStore.Object {
        let object = T()
        add(object)
        return object
    }

    @discardableResult public func create<T>(_: T.Type) -> T where T: ObjectPersistence.Object {
        let object = T()
        return object
    }

    public subscript<T>(_ type: T.Type, _ name: String) -> T where T: CacheDatabaseDocument {
        guard let mirror = mirror(for: Cache<T>.self).first else {
            guard let document = containerDocument?[type, name] else { fatalError("Cache for \(T.self) not found") }
            return document
        }
        return mirror.value[name]
    }

    public func callAsFunction<T>(_ type: T.Type) -> T where T: ObjectStore.Object {
        create(type)
    }

    public func delete<T>(_ item: T) where T: ObjectStore.Object {
        try! deleteObject(item: item)
    }

//    subscript<T>(dynamicMember dynamicMember: String) ->  T where T: PropertyStorage {
//        guard let storage = self[KeyPath]
//    }
//
    public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<DatabaseDocument, T>) -> T where T: PropertyStore {
        get { self[keyPath: keyPath] }
        set { self[keyPath: keyPath] = newValue }
    }

    func change(by change: () -> Void) {
        guard !readOnly else { return }

        let didStart = !isActive
        if didStart {
            writingTimestamp = Date.now
        }
        change()
        if didStart {
            writingTimestamp = nil
        }
    }

    func deleteObject<T>(item: T) throws where T: ObjectStore.Object {
        var didDelete = false
        for storage in storages {
            do {
                try storage.deleteObject(item: item)
                didDelete = true
            } catch {}
        }
        if let containerDocument {
            try containerDocument.deleteObject(item: item)
            didDelete = true
        }
        guard didDelete else {
            fatalError("Storage for \(T.self) not found")
        }
    }

    func removeReferences<T>(to item: T) where T: ObjectStore.Object {
        for storage in storages {
            storage.removeReferences(to: item)
        }
    }

    func getObject<T>(type: T.Type, id: T.ID) throws -> T? where T: ObjectStore.Object {
        for storage in storages {
            do {
                return try storage.getObject(type: type, id: id)
            } catch {}
        }
        if let containerDocument {
            return try containerDocument.getObject(type: type, id: id)
        }
        fatalError("Storage for \(type.self) not found")
    }

    func getObjects<T>(type: T.Type) throws -> Set<T> where T: ObjectStore.Object {
        for storage in storages {
            do {
                return try storage.getObjects(type: type)
            } catch {}
        }
        if let containerDocument {
            return try containerDocument.getObjects(type: type)
        }
        fatalError("Storage for \(type) not found")
    }

    func addObject<T>(item: T) throws where T: ObjectStore.Object {
        for storage in storages {
            do {
                try storage.addObject(item: item)
                return
            } catch {}
        }
        if let containerDocument {
            return try containerDocument.addObject(item: item)
        }
        fatalError("Storage for \(T.self) not found")
    }
}
