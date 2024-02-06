//
//  Database.Object.swift
//  Hippocampus
//
//  Created by Guido Kühn on 29.04.23.
//

import Foundation

extension DataStore {
    open class TimedObject: Object {
        @Serialized private(set) var timedValues: [Key: TimeLine<ValueStorage>] = [:]

        override public subscript<T>(_ type: T.Type, _ key: Key, timestamp timestamp: Date? = nil) -> T? where T: PersistentValue {
            get {
                timedValues[key]?.timedValue(at: readingTimestamp)?[type: T.self]
            }
            set {
                guard newValue != self[type, key] else { return }
                change { [self] in
                    if timedValues[key] == nil {
                        timedValues[key] = TimeLine()
                    }
                    timedValues[key]![type: T.self, at: writingTimestamp] = newValue
                }
            }
        }

        override public func value(key: Key) -> (any PersistentValue)? {
            timedValues[key]?.timedValue(at: readingTimestamp)?.value
        }

        // MARK: - Merging

        override open func merge(other: Mergeable) throws {
            guard let other = other as? Self, other.id == id else { return }

            willChange()

            if let added, let otherAdded = other.added, added < otherAdded { self.added = other.added }

            Set(timedValues.keys).intersection(Set(other.timedValues.keys))
                .forEach { key in
                    timedValues[key] = timedValues[key]!.merged(with: other.timedValues[key]!)
                }

            Set(other.timedValues.keys).subtracting(Set(timedValues.keys))
                .forEach { key in
                    timedValues[key] = other.timedValues[key]!
                }
        }
    }

    open class Object: ObjectStore.Object, Mergeable {
        @Serialized private(set) var values: [Key: TimedValue<ValueStorage>] = [:]
        @Serialized var added: Date?
        @Property var deleted: Bool = false

        // MARK: - Changes

        func change(by change: @escaping () -> ()) {
            guard !readOnly else { return }

            let action = { [self] in
                objectWillChange.send()
                store?.willChange()
                change()
                store?.didChange()
            }

            if let document {
                document.change {
                    action()
                }
            } else {
                action()
            }
        }

        func willChange() {
            objectWillChange.send()
        }

        // MARK: - Timing

        var readingTimestamp: Date { document?.readingTimestamp ?? Date.distantFuture }
        var writingTimestamp: Date { document?.writingTimestamp ?? Date.distantPast }

        // MARK: - State

        public subscript<T>(_ type: T.Type, _ key: Key, timestamp timestamp: Date? = nil) -> T? where T: PersistentValue {
            get {
                values[key]?[type: T.self]
            }
            set {
                guard newValue != self[type, key] else { return }
                change { [self] in
                    values[key] = TimedValue(time: writingTimestamp, value: newValue)
                }
            }
        }

        public func value(key: Key) -> (any PersistentValue)? {
            values[key]?.value
        }

        // MARK: - Merging

        open func merge(other: Mergeable) throws {
            guard let other = other as? Self, other.id == id else { return }

            willChange()

            if let added, let otherAdded = other.added, added < otherAdded { self.added = other.added }

            Set(values.keys).intersection(Set(other.values.keys))
                .forEach { key in
                    let own = values[key]!
                    let other = other.values[key]!
                    if own.time < other.time {
                        values[key] = other
                    }
                }

            Set(other.values.keys).subtracting(Set(values.keys))
                .forEach { key in
                    values[key] = other.values[key]!
                }
        }
    }
}
