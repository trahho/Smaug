//
//  IdentifiableObject.swift
//  Hippocampus (iOS)
//
//  Created by Guido Kühn on 02.12.22.
//

import Foundation

open class IdentifiableObject: Identifiable, Hashable {
//    public typealias ID = UUID
    public typealias ID = UUID

    @Serialized public var id: ID = UUID()

    public static func == (lhs: IdentifiableObject, rhs: IdentifiableObject) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public init() {}
}
