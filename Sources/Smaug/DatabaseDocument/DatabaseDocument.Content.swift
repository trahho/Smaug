//
//  DatabaseDocument.Content.swift
//  Hippocampus
//
//  Created by Guido Kühn on 30.04.23.
//

import Combine
import Foundation

public extension DatabaseDocument {

    @propertyWrapper
    final class Content<T>: Storage where T: Persistent {
        // MARK: - Initialization

        public init(wrappedValue: @autoclosure @escaping () -> T, publishChange: Bool = true, commitOnChange: Bool = true) {
            content = wrappedValue
            self.commitOnChange = commitOnChange
            self.publishChange = publishChange
        }

        // MARK: - Content

        var container: PersistentContainer<T>!
        var content: () -> T
        var commitOnChange: Bool
        var publishChange: Bool
        var cancellable: AnyCancellable!

        override func setup(url: URL, name: String, document: DatabaseDocument) {
            let content = content()
            self.document = document
            let url = url.appending(component: name + ".persistent")
            container = PersistentContainer(url: url, content: content, commitOnChange: commitOnChange)
            if publishChange {
                cancellable = container.objectWillChange.sink { document.objectWillChange.send() }
            }
        }

        // MARK: - Wrapping

        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: T {
            get { fatalError() }
            set { fatalError() }
        }

        public static subscript<Enclosing: DatabaseDocument>(_enclosingInstance instance: Enclosing,
                                                             wrapped _: ReferenceWritableKeyPath<Enclosing, T>,
                                                             storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Content>) -> T
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                return storage.container.content
            }
            set {}
        }
    }
}
