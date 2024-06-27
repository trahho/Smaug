//
//  File.swift
//
//
//  Created by Guido Kühn on 04.05.23.
//

import Foundation

public extension Array where Element: Hashable {
    var asSet: Set<Element> {
        Set(self)
    }

    func asDictionary<Key: Hashable>(key: KeyPath<Self.Element, Key>) -> [Key: Self.Element] {
        reduce(into: [:]) { dictionary, element in
            dictionary[element[keyPath: key]] = element
        }
    }
}


public extension Array where Element: ObjectStore.Object {
    mutating func remove(item: Element) {
        guard let index = firstIndex(of: item) else { return }
        remove(at: index)
    }
}

public extension Array where Element: ObjectPersistence.Object {
    mutating func remove(item: Element) {
        guard let index = firstIndex(of: item) else { return }
        remove(at: index)
    }
}
