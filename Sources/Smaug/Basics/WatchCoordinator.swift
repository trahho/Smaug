//
//  WatchCoordinator_watchOS.swift
//  Smaug
//
//  Created by Guido Kühn on 15.03.25.
//
#if os(watchOS) || os(iOS)

    import WatchConnectivity

    public class WatchCoordinator: NSObject {
        // MARK: Nested Types

        typealias Message = [String: Data]

        // MARK: Static Properties

        public nonisolated(unsafe) static let shared = WatchCoordinator()

        // MARK: Properties

        public let log = Log()

        let emptyMessage: Message = ["": Data()]
        let session: WCSession
        var containers: [String: CoordinatorPersistentContainerWeakReference] = [:]
        var delayedMessage: Message = [:]
        var onDelay = false

        // MARK: Computed Properties

        #if os(iOS)
            var isActive: Bool {
                WCSession.isSupported() && session.isWatchAppInstalled  /*&& session.isReachable*/
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
                log.log("WCSession activated")
            }
        }

        // MARK: Functions

        public func registerContainer(container: CoordinatorPersistentContainer) {
            log.log("registerContainer \(container.identifier)")
            containers[container.identifier] = CoordinatorPersistentContainerWeakReference(container: container)
        }

        func container(for identifier: String) -> CoordinatorPersistentContainer? {
            guard let reference = containers[identifier] else { return nil }
            guard let container = reference.container else {
                containers[identifier] = nil
                return nil
            }
            return container
        }

        func sendFile(container: CoordinatorPersistentContainer) {
            guard isActive else {
                log.log("sendFile isActive false")
                return
            }
            guard let url = container.showFileURL() else {
                log.log("sendFile no url")
                return
            }
            log.log("sendFile \(container.identifier)")
            let fileId = UUID().uuidString
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileId)
            try! FileManager.default.copyItem(at: url, to: tempURL)
            session.outstandingFileTransfers
                .filter { $0.file.metadata?["id"] as? String == container.identifier }
                .forEach {
                    $0.cancel()
                    try? FileManager.default.removeItem(at: $0.file.fileURL)
                }
            session.transferFile(tempURL, metadata: ["id": container.identifier])
        }

        func getFile(file: WCSessionFile) {
            guard let containerId = file.metadata?["id"] as? String else { return }
            log.log("getFile \(containerId)")
            guard let container = container(for: containerId) else { return }
            container.receiveFileURL(file.fileURL)
        }

//        func sendData(container: CoordinatorPersistentContainer) {
//            if self.container(for: container.identifier) !== container {
//                registerContainer(container: container)
//            }
//            guard let data = container.showData() else {
//                log.log("sendData no data")
//                return
//            }
//
//            guard !onDelay else {
//                log.log("sendData onDelay, delay 1")
//                delayedMessage[container.identifier] = data
//                return
//            }
//
//            guard isActive else {
//                log.log("sendData isActive false, delay 1")
//                delayedMessage[container.identifier] = data
//                onDelay = true
//                return
//            }
//            log.log("sendData 1")
//            sendMessage([container.identifier: data])
//        }
//
//        func getMessage(_ message: [String: Any]) {
//            print("Get Data")
//            message.forEach { key, data in
//                guard !key.isEmpty, let container = container(for: key), let data = data as? Data else { return }
//                log.log("getMessage \(key)")
//                container.receiveData(data: data)
//            }
//        }
//
//        func sendMessage(_ message: Message) {
//            //                session.transferUserInfo(userInfo)
//            let message = delayedMessage.merging(message, uniquingKeysWith: { _, new in new })
//            delayedMessage = [:]
//            guard !message.isEmpty else {
//                log.log("sendMessage is empty")
//                return
//            }
//            guard !onDelay else {
//                delayedMessage = message.filter { !$0.key.isEmpty }
//                log.log("sendMessage onDelay, delay \(delayedMessage.count)")
//                return
//            }
//            print("Send Data")
//            log.log("sendMessage \(message.count)")
//            session.sendMessage(message) {
//                [self] reply in
//                log.log("sendMessage get reply \(reply.count)")
//                getMessage(reply)
//            } errorHandler: { [self]
//                error in print("error sending message: \(String(describing: error))")
//                    log.log("sendMessage error \(String(describing: error)) delayed \(message.count)")
//
//                    self.delayedMessage = message
//                    self.onDelay = true
        ////                    DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 1_000_000_000)) { [self] in sendMessage(delayedMessage) }
//            }
//        }
    }
#endif
