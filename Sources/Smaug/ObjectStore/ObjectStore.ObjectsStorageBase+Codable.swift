//
//  File.swift
//
//
//  Created by Guido Kühn on 06.05.23.
//

import Foundation

extension ObjectStore.ObjectsStorageBase: PersistentProperty where T: Encodable {
    struct Coded: Codable {
        var deletedTimestamp: Date?
        var values: [T]
    }

    func encode(into container: inout EncodingContainer, key: PersistentCodingKey) throws {
        guard !(storage.isEmpty && deletedTimestamp == nil) else { return }
        let coded = Coded(deletedTimestamp: deletedTimestamp, values: Array(storage.values))
        try container.encodeIfPresent(coded, forKey: key)
    }
    
    func decode(from container: DecodingContainer, key: PersistentCodingKey) throws {
        if let coded = try? container.decodeIfPresent(Coded.self, forKey: key) {
            deletedTimestamp = coded.deletedTimestamp
            storage = Dictionary(uniqueKeysWithValues: coded.values.map { ($0.id, $0) })
        }
    }
}
