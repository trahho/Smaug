//
//  File.swift
//  
//
//  Created by Guido Kühn on 23.02.24.
//

import Foundation
import Observation

public protocol ObservationInstance: Observable {
    var observationRegistrar: Observation.ObservationRegistrar { get }
}

