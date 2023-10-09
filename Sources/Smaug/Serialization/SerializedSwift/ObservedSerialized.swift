////
////  File.swift
////
////
////  Created by Dejan Skledar on 07/09/2020.
////
//
//import Combine
//import Foundation
//
//@propertyWrapper
///// Property wrapper for Serializable (Encodable + Decodable) properties.
///// The Object itself must conform to Serializable (or SerializableEncodable / SerializableDecodable)
///// Default value is by default nil. Can be used directly without arguments
//public class ObservedSerialized<T: ObservableObject> {
//    var key: String?
//    var alternateKey: String?
//    var cancellable: AnyCancellable?
//
//    private var _value: T? {
//        didSet { cancellable = nil }
//    }
//
//    @available(*, unavailable, message: "This property wrapper can only be applied to classes")
//    public var wrappedValue: T {
//        get { fatalError() }
//        set { fatalError() }
//    }
//
//    /// Wrapped value getter for optionals
//    private func _wrappedValue<U>(_: U.Type) -> U? where U: ExpressibleByNilLiteral {
//        _value as? U
//    }
//
//    /// Wrapped value getter for non-optionals
//    private func _wrappedValue<U>(_: U.Type) -> U {
//        _value as! U
//    }
//
//    public static subscript<EnclosingSelf: ObservableObject>(
//        _enclosingInstance instance: EnclosingSelf,
//        wrapped _: ReferenceWritableKeyPath<EnclosingSelf, T>,
//        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, ObservedSerialized>
//    ) -> T {
//        get {
//            let storage = instance[keyPath: storageKeyPath]
//            let result = storage._wrappedValue(T.self)
//            if storage.cancellable == nil {
//                storage.cancellable = result.objectWillChange.sink(receiveValue: { _ in
//                    if let receiver = instance as? ObservedChangesReceiver {
//                        receiver.willChange(observedObject: result)
//                        return
//                    }
//                    if let publisher = instance.objectWillChange as? Combine.ObservableObjectPublisher {
//                        publisher.send()
//                    }
//                })
//            }
//            return result
//        }
//        set {
//            let storage = instance[keyPath: storageKeyPath]
//            if let publisher = instance.objectWillChange as? Combine.ObservableObjectPublisher {
//                publisher.send()
//            }
//            storage._value = newValue
//        }
//    }
//
//    /// Defualt init for Serialized wrapper
//    /// - Parameters:
//    ///   - key: The JSON decoding key to be used. If `nil` (or not passed), the property name gets used for decoding
//    ///   - alternateKey: The alternative JSON decoding key to be used, if the primary decoding key fails
//    ///   - value: The default value to be used, if the decoding fails. If not passed, `nil` is used.
//    public init(wrappedValue: @autoclosure @escaping () -> T, _ key: String? = nil, alternateKey: String? = nil) {
//        self.key = key
//        self.alternateKey = alternateKey
//        _value = wrappedValue()
//    }
//
//    public init(_ key: String? = nil, alternateKey: String? = nil) {
//        self.key = key
//        self.alternateKey = alternateKey
//        _value = nil
//    }
//}
//
///// Encodable support
//extension ObservedSerialized: EncodableProperty where T: Encodable {
//    /// Basic property encoding with the key (if present), or propertyName if key not present
//    /// - Parameters:
//    ///   - container: The default container
//    ///   - propertyName: The Property Name to be used, if key is not present
//    /// - Throws: Throws JSON encoding errorj
//    public func encodeValue(from container: inout EncodeContainer, propertyName: String) throws {
//        let codingKey = SerializedCodingKeys(key: key ?? propertyName)
//        try container.encodeIfPresent(_wrappedValue(T.self), forKey: codingKey)
//    }
//}
//
///// Decodable support
//extension ObservedSerialized: DecodableProperty where T: Decodable {
//    /// Adding the DecodableProperty support for Serialized annotated objects, where the Object conforms to Decodable
//    /// - Parameters:
//    ///   - container: The decoding container
//    ///   - propertyName: The property name of the Wrapped property. Used if no key (or nil) is present
//    /// - Throws: Doesnt throws anything; Sets the wrappedValue to nil instead (possible crash for non-optionals if no default value was set)
//    public func decodeValue(from container: DecodeContainer, propertyName: String) throws {
//        let codingKey = SerializedCodingKeys(key: key ?? propertyName)
//
//        if let value = try? container.decodeIfPresent(T.self, forKey: codingKey) {
//            _value = value
//        } else {
//            guard let altKey = alternateKey else { return }
//            let altCodingKey = SerializedCodingKeys(key: altKey)
//            if let value = try? container.decodeIfPresent(T.self, forKey: altCodingKey) {
//                _value = value
//            }
//        }
//    }
//}
