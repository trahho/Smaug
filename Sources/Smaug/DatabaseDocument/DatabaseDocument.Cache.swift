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
    final class Cache<T>: Storage where T: DatabaseDocument {
        // MARK: - Types

        struct CacheItem {
            weak var document: T?
            let cancellable: AnyCancellable?

            init(document: T, cancellable: AnyCancellable?) {
                self.document = document
                self.cancellable = cancellable
            }
        }

        // MARK: - Initialization

        public init(publishChange: Bool = false) {
            self.publishChange = publishChange
        }

        // MARK: - Content

        var parent: DatabaseDocument!
        var publishChange: Bool
        var url: URL!

        var cancellable: AnyCancellable?

        override func setup(url: URL, name: String, document parent: DatabaseDocument) {
            self.url = url.appending(component: name)
            self.parent = parent
        }

        // MARK: - Storage

        private var cache: [String: CacheItem] = [:]

        subscript(name: String) -> T {
            if let document = cache[name]?.document {
                return document
            } else {
                let document = T(url: url, containerDocument: parent)
                var cancellable: AnyCancellable?
                if publishChange {
                    cancellable = document.objectWillChange.sink(receiveValue: { [self] in parent.objectWillChange.send() })
                }
                cache[name] = CacheItem(document: document, cancellable: cancellable)
                return document
            }
        }

        // MARK: - Wrapping

//        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: T {
            get { fatalError() }
            set { fatalError() }
        }

//        public static subscript<Enclosing: DatabaseDocument>(_enclosingInstance instance: Enclosing,
//                                                             wrapped _: ReferenceWritableKeyPath<Enclosing, T>,
//                                                             storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Cache>) -> T
//        {
//            get {
//                fatal
//            }
//            set {}
//        }
    }
}
