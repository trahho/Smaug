//
//  Database.Property.swift
//  Hippocampus
//
//  Created by Guido Kühn on 29.04.23.
//

import Foundation

public extension ObjectStore.Object {
    @propertyWrapper final class Property<Value> where Value: DataStore.PersistentValue {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value {
            get { fatalError() }
            set { fatalError() }
        }
        
        private var defaultValue: (() -> Value)?
        private var value: Value?
        
        public init(wrappedValue: @autoclosure @escaping () -> Value) {
            defaultValue = wrappedValue
        }
        
        public init() {}
        
        public static subscript<Enclosing: ObjectStore.Object>(_enclosingInstance instance: Enclosing,
                                                               wrapped _: ReferenceWritableKeyPath<Enclosing, Value>,
                                                               storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Property>) -> Value
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                if let value = storage.value {
                    return value
                } else {
                    return storage.defaultValue!()
                }
            }
            set {
                guard !instance.readOnly else { return }
                let storage = instance[keyPath: storageKeyPath]
                storage.value = newValue
            }
        }
    }
}
