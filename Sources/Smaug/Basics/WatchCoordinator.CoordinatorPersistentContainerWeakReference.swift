//
//  CoordinatorPersistentContainerWeakReference.swift
//  Smaug
//
//  Created by Guido Kühn on 12.04.25.
//

#if os(watchOS) || os(iOS)

import WatchConnectivity

extension WatchCoordinator {
        class CoordinatorPersistentContainerWeakReference {
            // MARK: Properties

            weak var container: CoordinatorPersistentContainer?

            // MARK: Lifecycle

            init(container: CoordinatorPersistentContainer) {
                self.container = container
            }
        }
    }
#endif
