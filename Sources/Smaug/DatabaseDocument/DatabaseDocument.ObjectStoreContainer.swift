//
//  File.swift
//  
//
//  Created by Guido Kühn on 04.05.23.
//

import Foundation

extension DatabaseDocument {
    class ObjectStoreContainer<T>: PersistentContainer<T> where T: ObjectStore {
        var document: DatabaseDocument

        init(document: DatabaseDocument, url: URL, content: T, commitOnChange: Bool = false, configureContent: PersistentContainer<T>.ContentDelegate? = nil) {
            self.document = document
            super.init(url: url, content: content, commitOnChange: commitOnChange, configureContent: configureContent)
        }

        override func restore(content: T) {
            super.restore(content: content)
            content.document = document
        }
        
        public func setContent(content: T) {
            restore(content: content)
            self.content = content
        }
    }
}
