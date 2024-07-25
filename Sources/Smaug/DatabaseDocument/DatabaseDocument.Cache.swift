//
//  DatabaseDocument.Cache.swift
//  Hippocampus
//
//  Created by Guido Kühn on 30.04.23.
//

import Combine
import Foundation

public extension DatabaseDocument {
  

    @propertyWrapper
    final class Cache<T>: Storage where T: CacheDatabaseDocument {
        // MARK: Nested Types

        // MARK: - Types

        struct CacheItem {
            // MARK: Properties

            weak var document: T?

            // MARK: Lifecycle

            init(document: T) {
                self.document = document
            }
        }

        // MARK: Properties

        var parent: DatabaseDocument!
        var publishChange: Bool
        var url: URL!

        var cancellable: AnyCancellable?

        // MARK: - Storage

        private var cache: [String: CacheItem] = [:]

        // MARK: Computed Properties

        // MARK: - Wrapping

//        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: T {
            get { fatalError() }
            set { fatalError() }
        }

        public var projectedValue: [String] {
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: url.path) else { return [] }
            return contents.map { URL(filePath: $0).lastPathComponent }
        }

        // MARK: Lifecycle

        // MARK: - Initialization

        public init(publishChange: Bool = false) {
            self.publishChange = publishChange
        }

        // MARK: Overridden Functions

        override func setup(url: URL, name: String, document parent: DatabaseDocument) {
            self.url = url.appending(component: name)
            self.parent = parent
        }

        // MARK: Functions

        subscript(name: String) -> T {
            if let document = cache[name]?.document {
                return document
            } else {
                let url = url.appending(component: name)
                let document = T(url: url, containerDocument: parent)

                cache[name] = CacheItem(document: document)
                return document
            }
        }
    }
}
