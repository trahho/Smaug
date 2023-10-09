//
//  Database.swift
//  Hippocampus
//
//  Created by Guido Kühn on 29.04.23.
//

import Foundation

/// Jetzt kommt eine database, die aus mehreren databases besteht. Das wird ein Document. Und einen eigenen Container DatabaseContainer
/// Das restore verliert wieder den content, denn der Container weiß es selber. Er gibt der Database sich selbst, und erhält vom Document

open class DataStore<ValueStorage: TimedValueStorage>: ObjectStore {
    public typealias PersistentValue = TimedValueStorage.PersistentValue
    public typealias Key = String

    @Serialized var timestamps: Set<Date>

    override public func merge(other: Mergeable) throws {
        guard let other = other as? Self else { throw MergeError.wrongMatch }
        try super.merge(other: other)
        timestamps = timestamps.union(other.timestamps)
    }
    
    override func addObject<T>(item: T) throws where T: ObjectStore.Object {
        guard !document.readOnly else { return }
        if let item = item as? Object {
            item.added = document.writingTimestamp
        }
        try super.addObject(item: item)
    }
}
