//
//  File.swift
//  
//
//  Created by Guido Kühn on 06.05.23.
//

import Foundation

extension ObjectStore.ObjectsStorageBase: EncodableProperty where T: Encodable {
    public func encodeValue(from container: inout EncodeContainer, propertyName: String) throws {
        guard !storage.isEmpty else { return }
        let codingKey = SerializedCodingKeys(key: propertyName)
        let value = Array(storage.values)
        try container.encodeIfPresent(value, forKey: codingKey)
    }
}

extension ObjectStore.ObjectsStorageBase: DecodableProperty where T: Decodable {
    public func decodeValue(from container: DecodeContainer, propertyName: String) throws {
        let codingKey = SerializedCodingKeys(key: propertyName)
        if let value = try? container.decodeIfPresent([T].self, forKey: codingKey) {
            storage = Dictionary(uniqueKeysWithValues: value.map { ($0.id, $0) })
        }
    }
}
