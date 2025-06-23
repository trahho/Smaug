//
//  Log.swift
//  Smaug
//
//  Created by Guido Kühn on 12.04.25.
//

#if os(watchOS) || os(iOS)

import WatchConnectivity

public extension WatchCoordinator {
    @Observable class Log {
        // MARK: Nested Types

        public struct Entry {
            public let date: Date
            public let text: String
        }

        // MARK: Properties

        public var entries: [Entry] = []

        // MARK: Functions

        func log(_ text: String) {
            entries.append(.init(date: Date(), text: text))
        }
    }
}
#endif
