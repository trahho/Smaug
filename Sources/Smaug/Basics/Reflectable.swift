//
//  Reflectable.swift
//  Hippocampus
//
//  Created by Guido Kühn on 29.04.23.
//

import Foundation

protocol Reflectable {
    func mirror<T>(for _: T.Type) -> [(label: String?, value: T)]
}

extension Reflectable {
    func mirror<T>(for _: T.Type) -> [(label: String?, value: T)] {
        var result: [(label: String?, value: T)] = []
        var mirror: Mirror? = Mirror(reflecting: self)
        repeat {
            guard let children = mirror?.children else { break }
            for child in children {
                if let value = child.value as? T {
                    result.append((label: child.label, value: value))
                }
            }
            mirror = mirror?.superclassMirror
        } while mirror != nil
        return result
    }
}
