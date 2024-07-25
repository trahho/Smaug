//
//  CacheDatabaseDocument.swift
//  Smaug
//
//  Created by Guido Kühn on 25.07.24.
//

open class CacheDatabaseDocument: DatabaseDocument, Identifiable {
    public var id: String {
        url.absoluteString
    }
}
