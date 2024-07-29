//
//  PersistentContent.swift
//  Hippocampus
//
//  Created by Guido Kühn on 02.12.22.
//

import Combine
import Foundation

public protocol PersistentContent: DidChangeNotifier {
//    var container: PersistentContainer<Self> { get set }
    func encode() -> Data?
    static func decode(persistentData: Data) -> Self?
}

public extension PersistentContent where Self: Codable {
    func encode() -> Data? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return data
    }

    static func decode(persistentData: Data) -> Self? {
        guard let newContent = try? JSONDecoder().decode(Self.self, from: persistentData) else { return nil }
        return newContent
    }
}

protocol Persistent: Codable {
    init()
    func encode(into container: inout EncodingContainer) throws
    func decode(from container: DecodingContainer) throws
}

extension Persistent {
    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: PersistentCodingKey.self)
        try decode(from: container)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PersistentCodingKey.self)
        try encode(into: &container)
    }
}
