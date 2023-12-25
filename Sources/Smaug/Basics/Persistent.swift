//
//  PersistentContent.swift
//  Hippocampus
//
//  Created by Guido Kühn on 02.12.22.
//

import Combine
import Foundation

public protocol Persistent: DidChangeNotifier {
//    var container: PersistentContainer<Self> { get set }
    func encode() -> Data?
    static func decode(persistentData: Data) -> Self?
}

public extension Persistent where Self: Serializable {
    func encode() -> Data? {
        guard
            let data = try? JSONEncoder().encode(self)

//            , let compressedData = try? (data as NSData).compressed(using: .lzfse) as Data
        else { return nil }

        return data
//        return compressedData
    }

    static func decode(persistentData: Data) -> Self? {
        guard
//            let data = try? (persistentData as NSData).decompressed(using: .lzfse) as Data,
            // let newContent = try? JSONDecoder().decode(Self.self, from: data)
            let newContent = try? JSONDecoder().decode(Self.self, from: persistentData)

        else { return nil }
        return newContent
    }
}
