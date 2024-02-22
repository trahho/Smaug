//
//  File.swift
//  
//
//  Created by Guido Kühn on 22.02.24.
//

import Foundation
struct PersistentCodingKey: CodingKey {
   public var stringValue: String
   public var intValue: Int?

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

protocol PersistentProperty {
    typealias EncodingContainer = KeyedEncodingContainer<PersistentCodingKey>
    typealias DecodingContainer = KeyedDecodingContainer<PersistentCodingKey>

    func encode(into container: inout EncodingContainer, key: PersistentCodingKey) throws
    func decode(from container: DecodingContainer, key: PersistentCodingKey) throws
}
