//
//  File.swift
//
//
//  Created by Guido Kühn on 05.06.24.
//

import Foundation

extension ObjectPersistence {
    open class Object: ObjectStore.ObjectBase {
        func duplicate() -> Self {
            let result = Self()
            for (own, other) in zip(mirror(for: ObjectPersistence.Object.PropertyBase.self), result.mirror(for: ObjectPersistence.Object.PropertyBase.self)) {
                other.value.takeValue(other: own.value)
            }
            return result
        }
    }
}
