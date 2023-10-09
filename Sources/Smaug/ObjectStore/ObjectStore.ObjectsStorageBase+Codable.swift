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
        let codingKey = SerializedCodingKeys(key: key ?? propertyName)
        let value = Array(storage.values)
        try container.encodeIfPresent(value, forKey: codingKey)
    }
}

extension ObjectStore.ObjectsStorageBase: DecodableProperty where T: Decodable {
    public func decodeValue(from container: DecodeContainer, propertyName: String) throws {
        let codingKey = SerializedCodingKeys(key: key ?? propertyName)
        if let value = try? container.decodeIfPresent([T].self, forKey: codingKey) {
            storage = Dictionary(uniqueKeysWithValues: value.map { ($0.id, $0) })
        } else {
            guard let altKey = alternateKey else { return }
            let altCodingKey = SerializedCodingKeys(key: altKey)
            if let value = try? container.decodeIfPresent(Set<T>.self, forKey: altCodingKey) {
                storage = Dictionary(uniqueKeysWithValues: value.map { ($0.id, $0) })
            }
        }
    }
}
