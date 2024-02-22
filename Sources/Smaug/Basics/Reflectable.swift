//
//  Reflectable.swift
//  Hippocampus
//
//  Created by Guido Kühn on 29.04.23.
//

import Foundation

public protocol Reflectable {
    typealias Item<Value> = (label: String, value: Value)

    func mirror<T>(for _: T.Type) -> [Item<T>]
}

extension Reflectable {
    public func mirror<T>(for _: T.Type) -> [Item<T>] {
        var result: [Item<T>] = []
        var mirror: Mirror? = Mirror(reflecting: self)
        repeat {
            guard let children = mirror?.children else { break }
            for child in children {
                if let value = child.value as? T {
                    result.append((label: String((child.label ?? "").dropFirst()), value: value))
                }
            }
            mirror = mirror?.superclassMirror
        } while mirror != nil
        return result
    }
}
