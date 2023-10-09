//
//  ValueStorage.swift
//  Hippocampus
//
//  Created by Guido Kühn on 11.04.23.
//

import Foundation
public protocol TimedValueStorage: Codable, Equatable {
    typealias PersistentValue = Codable & Equatable

    init?(_ value: (any PersistentValue)?)
    var value: (any PersistentValue)? { get }
}
