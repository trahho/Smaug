//
//  Transient.swift
//  Smaug
//
//  Created by Guido Kühn on 31.07.24.
//


public extension ObjectStore {
    @propertyWrapper final class Transient<Value>: ObjectPropertyWrapper {
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Value {
            get { fatalError() }
            set { fatalError() }
        }
        
        private var _value: Value?
        weak var instance: ObjectStore?
        
        private func value<U>(_: U.Type) -> U? where U: ExpressibleByNilLiteral {
            _value as? U
        }
        
        private func value<U>(_: U.Type) -> U {
            _value as! U
        }
        
    
        public init(wrappedValue: @autoclosure @escaping () -> Value) {
            _value = wrappedValue()
        }
        
        public static subscript<Enclosing>(_enclosingInstance instance: Enclosing,
                                           wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Value>,
                                           storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Transient>) -> Value where Enclosing: ObjectStore
        {
            get {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                storage.showAccess()
                return storage.value(Value.self)
            }
            set {
                let storage = instance[keyPath: storageKeyPath]
                storage.instance = instance
                storage.configureObservation(instance: instance, keyPath: wrappedKeyPath)
                try! storage.withMutation {
                    storage._value = newValue
                }
            }
        }
    }
}
