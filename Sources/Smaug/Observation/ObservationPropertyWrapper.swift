//
//  File.swift
//
//
//  Created by Guido Kühn on 22.02.24.
//

import Foundation

public class ObservationPropertyWrapper {
    typealias Action = AccessAction
    typealias AccessAction = () -> ()
    typealias MutationAction = (() throws -> ()) throws -> ()
    
    var withMutation: MutationAction = {
        action in try action()
    }
    var showAccess: AccessAction = {}
    
    private var isSetup = false

    func configureObservation<Enclosing, T>(instance: Enclosing, keyPath: ReferenceWritableKeyPath<Enclosing, T>) where Enclosing: ObservationInstance {
        guard !isSetup else {
            return
        }
        isSetup = true
        withMutation = { action in
            try instance.observationRegistrar.withMutation(of: instance, keyPath: keyPath, action)
        }
        showAccess = {
            instance.observationRegistrar.access(instance, keyPath: keyPath)
        }
    }

    public init() {}
}

