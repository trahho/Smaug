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



public protocol Persistent: Codable {
    init()
    func decode(from decoder: Decoder) throws
}

extension Persistent {
    public init(from decoder: Decoder) throws {
        self.init()
        try decode(from: decoder)
    }
}
