//
//  File.swift
//
//
//  Created by Guido Kühn on 22.02.24.
//

import Foundation

public class ObservationPropertyStorage {
    var withMutation: ((() throws -> ()) throws -> ()) = { action in try action() }
    var showAccess: (() -> ()) = {}

    func configureObservation<Enclosing, T>(instance: Enclosing, keyPath: ReferenceWritableKeyPath<Enclosing, T>) where Enclosing: ObservationInstance {
        withMutation = { action in
            try instance.observationRegistrar.withMutation(of: instance, keyPath: keyPath, action)
            instance.didChange()
        }
        showAccess = {
            instance.observationRegistrar.access(instance, keyPath: keyPath)
        }
    }

    public init() {}
}

public protocol ObservationInstance: Observable {
    var observationRegistrar: Observation.ObservationRegistrar { get }
    func didChange()
}

public extension ObservationInstance {
    func didChange() {}
}

public extension ObservationInstance where Self:  DidChangeNotifier {
    func didChange() {
        objectDidChange.send()
    }
}
