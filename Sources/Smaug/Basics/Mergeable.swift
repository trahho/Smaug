//
//  MergeableContent.swift
//  Hippocampus
//
//  Created by Guido Kühn on 28.04.23.
//

import Foundation

public protocol Mergeable {
    func merge(other: any Mergeable) throws
}

public extension Mergeable {
    func merge(other: any Mergeable) throws {
        throw MergeError.mergeFailed
    }
}
