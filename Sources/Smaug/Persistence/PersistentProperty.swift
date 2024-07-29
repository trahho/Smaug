//
//  File.swift
//
//
//  Created by Guido Kühn on 22.02.24.
//

import Foundation

struct PersistentCodingKey: CodingKey {
    // MARK: Properties

    public var stringValue: String
    public var intValue: Int?

    // MARK: Lifecycle

    public init(key: String) {
        stringValue = key
    }

    public init?(stringValue: String) {
        self.stringValue = stringValue
    }

    public init?(intValue: Int) {
        self.intValue = intValue
        stringValue = String(intValue)
    }
}

typealias EncodingContainer = KeyedEncodingContainer<PersistentCodingKey>
typealias DecodingContainer = KeyedDecodingContainer<PersistentCodingKey>

protocol PersistentProperty {
    func encode(into container: inout EncodingContainer, key: PersistentCodingKey) throws
    func decode(from container: DecodingContainer, key: PersistentCodingKey) throws
}
