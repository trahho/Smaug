//
//  File.swift
//  
//
//  Created by Guido Kühn on 04.05.23.
//

import Foundation

extension Array where Element: Hashable {
    var asSet: Set<Element> {
        Set(self)
    }

    func asDictionary<Key: Hashable>(key: KeyPath<Self.Element, Key>) -> [Key: Self.Element] {
        reduce(into: [:]) { dictionary, element in
            dictionary[element[keyPath: key]] = element
        }
    }
}
