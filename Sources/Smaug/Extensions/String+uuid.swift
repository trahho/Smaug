//
//  File.swift
//  
//
//  Created by Guido Kühn on 19.06.24.
//

import Foundation

public extension String {
    var uuid: UUID { UUID(uuidString: self)! }
}
