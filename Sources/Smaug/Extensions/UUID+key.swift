//
//  UUID+key.swift
//  Hippocampus
//
//  Created by Guido Kühn on 30.04.23.
//

import Foundation

public extension UUID {
    var key: String {
        String(utf16CodeUnits: [
            UInt16(uuid.0) << 8 + UInt16(uuid.1),
            UInt16(uuid.2) << 8 + UInt16(uuid.3),
            UInt16(uuid.4) << 8 + UInt16(uuid.5),
            UInt16(uuid.6) << 8 + UInt16(uuid.7),
            UInt16(uuid.8) << 8 + UInt16(uuid.9),
            UInt16(uuid.10) << 8 + UInt16(uuid.11),
            UInt16(uuid.12) << 8 + UInt16(uuid.13),
            UInt16(uuid.14) << 8 + UInt16(uuid.15),
        ], count: 8)
    }

    init(key: String) {
        let c = Array(key.utf16)
        let uuid: uuid_t = (
            UInt8(c[0] >> 8), UInt8(c[0].byteSwapped >> 8),
            UInt8(c[1] >> 8), UInt8(c[1].byteSwapped >> 8),
            UInt8(c[2] >> 8), UInt8(c[2].byteSwapped >> 8),
            UInt8(c[3] >> 8), UInt8(c[3].byteSwapped >> 8),
            UInt8(c[4] >> 8), UInt8(c[4].byteSwapped >> 8),
            UInt8(c[5] >> 8), UInt8(c[5].byteSwapped >> 8),
            UInt8(c[6] >> 8), UInt8(c[6].byteSwapped >> 8),
            UInt8(c[7] >> 8), UInt8(c[7].byteSwapped >> 8)
        )
        self.init(uuid: uuid)
    }

    static var `nil`: UUID {
        let uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        return UUID(uuid: uuid)
    }
}
