//
//  WatchCoordinator_watchOS.swift
//  Smaug
//
//  Created by Guido Kühn on 15.03.25.
//
#if os(watchOS) || os(iOS)

    import WatchConnectivity

    protocol CoordinatorPersistentContainer: AnyObject {
        func receiveData(data: Data)
        func showData() -> Data?
        var identifier: String { get }
    }

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

    class WatchCoordinator: NSObject, WCSessionDelegate {
        // MARK: Static Properties

        static let shared = WatchCoordinator()

        // MARK: Properties

        let session: WCSession

        var containers: [String: CoordinatorPersistentContainerWeakReference] = [:]

        // MARK: Computed Properties

        #if os(iOS)
            var isActive: Bool {
                WCSession.isSupported() && session.isWatchAppInstalled && session.isReachable
            }
        #endif

        #if os(watchOS)
            var isActive: Bool {
                WCSession.isSupported() // && session.isCompanionAppInstalled && session.isReachable
            }
        #endif

        // MARK: Lifecycle

        override private init() {
            session = WCSession.default
            super.init()
            if WCSession.isSupported() {
                session.delegate = self
                session.activate()
            }
        }

        // MARK: Functions

        func container(for identifier: String) -> CoordinatorPersistentContainer? {
            guard let reference = containers[identifier] else { return nil }
            guard let container = reference.container else {
                containers[identifier] = nil
                return nil
            }
            return container
        }

        #if os(iOS)
            func sessionDidDeactivate(_ session: WCSession) {
                session.activate()
            }

            func sessionDidBecomeInactive(_ session: WCSession) {
                session.activate()
            }
        #endif

        func session(_: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            if let error {
                print("session activation failed with error: \(error.localizedDescription)")
                return
            }
//            if activationState == .activated {
//                var userInfo: [String: Data] = [:]
//                for identifier in containers.keys {
//                    guard let container = container(for: identifier), let data = container.showData() else { continue }
//                    userInfo[container.identifier] = data
//                }
//                try! session.updateApplicationContext(userInfo)
//            }
        }

        func session(_: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
            userInfo.forEach { key, data in
                guard let container = container(for: key), let data = data as? Data else { return }
                container.receiveData(data: data)
            }
        }

        func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
            applicationContext.forEach { key, data in
                guard let container = container(for: key), let data = data as? Data else { return }
                container.receiveData(data: data)
            }
        }

        func registerContainer(key: String, container: CoordinatorPersistentContainer) {
            containers[key] = CoordinatorPersistentContainerWeakReference(container: container)
        }

        func sendData(key: String) {
            guard isActive, let container = container(for: key), let data = container.showData() else { return }

            session.transferUserInfo([key: data])
        }
    }
#endif
