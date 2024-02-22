//
//  File.swift
//  
//
//  Created by Guido Kühn on 06.05.23.
//

import Foundation

extension ObjectStore.ObjectsStorageBase: EncodableProperty where T: Encodable {
    struct Coded: Codable {
        var deletedTimestamp: Date?
        var values: [T]
    }
    
    public func encodeValue(from container: inout EncodeContainer, propertyName: String) throws {
        guard !storage.isEmpty else { return }
        let codingKey = SerializedCodingKeys(key: propertyName)
        let coded = Coded(deletedTimestamp: deletedTimestamp, values: Array(storage.values))
        try container.encodeIfPresent(coded, forKey: codingKey)
    }
}

extension ObjectStore.ObjectsStorageBase: DecodableProperty where T: Decodable {
    public func decodeValue(from container: DecodeContainer, propertyName: String) throws {
        let codingKey = SerializedCodingKeys(key: propertyName)
        if let coded = try? container.decodeIfPresent(Coded.self, forKey: codingKey) {
            deletedTimestamp = coded.deletedTimestamp
            storage = Dictionary(uniqueKeysWithValues: coded.values.map { ($0.id, $0) })
        }
    }
}
