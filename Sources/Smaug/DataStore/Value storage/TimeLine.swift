//
//  PersistentGraph.Member.TimeLine.swift
//  Hippocampus
//
//  Created by Guido Kühn on 17.12.22.
//

import Foundation

struct TimeLine<Storage: TimedValueStorage>: Serializable {
    typealias Value = TimedValue<Storage>

    @Serialized private var values: [Value]

    var timestamp: Date? {
        values.last?.time
    }

    init() {
        values = []
    }

    init(_ startValue: any TimedValueStorage.PersistentValue) {
        values = [Value(time: Date.distantPast, value: startValue)]
    }

    init(_ values: [Value]) {
        self.values = values
    }

    func merged(with other: TimeLine) -> TimeLine {
        let temp = (values + other.values).sorted { $0.time < $1.time }
        guard !temp.isEmpty else { return TimeLine() }

        var result: [Value] = [temp.first!]
        temp.forEach { current in
            let last = result.last!
            if current.time > last.time, !isEqual(last.value, current.value) {
                result.append(current)
            }
        }
        return TimeLine(result)
    }

    func timedValue(at timestamp: Date) -> Value? {
        values.last(where: { $0.time <= timestamp })
    }

    subscript<T>(type type: T.Type, at timestamp: Date) -> T? where T: TimedValueStorage.PersistentValue {
        get {
            timedValue(at: timestamp)?[type: T.self]
        }
        set {
            if let last = values.last {
                if last[type: T.self] == newValue { return }
                if last.time > timestamp { return }
                if last.time == timestamp { values.removeLast() }
            }

            let newTimedValue = Value(time: timestamp, value: newValue)
            values.append(newTimedValue)
        }
    }

    func reset(before timestamp: Date) {
        values = values.filter { $0.time < timestamp }.sorted(by: { $0.time < $1.time })
    }
}
