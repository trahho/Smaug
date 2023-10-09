//
//  PersistentObject.swift
//  Hippocampus
//
//  Created by Guido Kühn on 09.08.22.
//

import Combine
import Foundation
 
open class PersistentObject: IdentifiableObject, Serializable {
    override public required init() {
        super.init()
    }
}
