//
//  File.swift
//
//
//  Created by Guido Kühn on 08.06.24.
//

import Foundation

protocol MergeablePropertyWrapper: AnyObject, Mergeable {
    func setStore(store _: ObjectStore)
}

extension MergeablePropertyWrapper {
    func setStore(store _: ObjectStore) {}
}
