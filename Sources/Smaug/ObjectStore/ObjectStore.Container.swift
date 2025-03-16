//
//  File.swift
//
//
//  Created by Guido Kühn on 04.05.23.
//

import Foundation

extension ObjectStore {
    class Container<T>: PersistentContainer<T> where T: ObjectStore {
        // MARK: Properties

        var document: DatabaseDocument

        // MARK: Lifecycle

        init(document: DatabaseDocument, url: URL, content: T, commitOnChange: Bool = false, configureContent: PersistentContainer<T>.ContentDelegate? = nil) {
            self.document = document
            super.init(url: url, content: content, commitOnChange: commitOnChange, configureContent: configureContent)
        }

        // MARK: Overridden Functions

        override func restore(content: T) {
            super.restore(content: content)
            content.document = document
        }

        // MARK: Functions

        public func setContent(content: T) {
            restore(content: content)
            self.content = content
        }
    }
}
