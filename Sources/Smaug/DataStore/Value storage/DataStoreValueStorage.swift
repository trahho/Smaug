//
//  ValueStorage.swift
//  Hippocampus
//
//  Created by Guido Kühn on 11.04.23.
//

import Foundation
public protocol DataStoreValueStorage: Codable, Equatable {
    typealias PersistentValue = Codable & Equatable

    init?(_ value: (any PersistentValue)?)
    var value: (any PersistentValue)? { get }
}
