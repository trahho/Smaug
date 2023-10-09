//
//  Box.swift
//  Gridlock
//
//  Created by Greg Omelaenko on 5/8/18.
//  Copyright © 2018 Greg Omelaenko. All rights reserved.
//

public class Box<Value> {
    fileprivate var value: Value

    public required init(_ value: Value) {
        self.value = value
    }

    public subscript() -> Value {
        value
    }

    public func mutableCopy() -> MutableBox<Value> {
        MutableBox(self[])
    }
}

extension Box: Equatable where Value: Equatable {
    public static func == (lhs: Box<Value>, rhs: Box<Value>) -> Bool {
        lhs[] == rhs[]
    }
}

public extension Box {
    func map<T>(_ transform: (Value) throws -> T) rethrows -> Box<T> {
        Box<T>(try transform(self[]))
    }
}

public class MutableBox<Value>: Box<Value> {
    override public subscript() -> Value {
        get {
            value
        }
        set {
            value = newValue
        }
    }
}
