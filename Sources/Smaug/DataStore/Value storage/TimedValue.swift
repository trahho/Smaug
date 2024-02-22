////
////  PersistentGraph.Member.TimedValue.swift
////  Hippocampus
////
////  Created by Guido Kühn on 17.12.22.
////
//
//import Foundation
//
//struct TimedValue<Storage: DataStoreValueStorage>: Codable, Equatable {
//    enum CodingKeys: String, CodingKey {
//        case time
//        case storage
//    }
//    
//
//    private(set) var time: Date
//    private(set) var storage: Storage?
//
//    var value: (any Storage.PersistentValue)? {
//        get {
//            storage?.value
//        }
//        set {
//            guard let newValue else {
//                storage = nil
//                return
//            }
//            storage = Storage(newValue)
//        }
//    }
//
//    subscript<T: DataStoreValueStorage.PersistentValue>(type _: T.Type) -> T? {
//        guard let value else { return nil }
//        return value as? T
//    }
//
//    init(time: Date, value: (any DataStoreValueStorage.PersistentValue)?) {
//        self.time = time
//        self.value = value
//    }
//}
