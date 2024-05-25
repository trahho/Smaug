//
//  Encodable+typeName.swift
//  Hippocampus
//
//  Created by Guido Kühn on 05.01.23.
//

import Foundation

public extension Encodable {
    private func getType<T: Encodable>(_: T) -> Any.Type {
        T.self
    }

    var typeType: Any.Type {
        getType(self)
    }

    var typeName: String {
        String(reflecting: typeType)
    }
}


