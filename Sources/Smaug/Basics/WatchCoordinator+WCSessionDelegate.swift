//
//  WatchCoordinator+WCSessionDelegate.swift
//  Smaug
//
//  Created by Guido Kühn on 23.03.25.
//

#if os(watchOS) || os(iOS)
    import WatchConnectivity

    extension WatchCoordinator: WCSessionDelegate {
//        public func sessionReachabilityDidChange(_ session: WCSession) {
//            log.log("sessionReachabilityDidChange: \(session.isReachable)")
//            if session.isReachable {
//                onDelay = false
//                sendMessage(emptyMessage)
//            } else {
//                onDelay = true
//            }
//        }

        public func session(_: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            if let error {
                log.log("activationDidCompleteWith error: \(error.localizedDescription)")
                onDelay = true
                return
            }
            let activationStateText = switch activationState {
            case .activated: "activated"
            case .notActivated: "notActivated"
            case .inactive: "inactive"
            default: "unknown"
            }
            log.log("activationDidCompleteWith: \(activationStateText)")

            if activationState == .activated {
//                var message: Message = [:]
//                for identifier in containers.keys {
//                    guard let container = container(for: identifier), let data = container.showData() else { continue }
//                    message[container.identifier] = data
//                }
                log.log("activationDidCompleteWith send \(delayedMessage.count)")
                onDelay = false
//                sendMessage(emptyMessage)
            } else {
                onDelay = true
            }
        }

//        public func session(_: WCSession, didReceiveMessage message: [String: Any]) {
//            log.log("didReceiveMessage \(message.count)")
//            getMessage(message)
//            if !delayedMessage.isEmpty {
//                sendMessage(delayedMessage)
//            }
//        }
//
//        public func session(_: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
//            log.log("didReceiveMessage \(message.count) reply \(delayedMessage.count)")
//            replyHandler(delayedMessage)
//            getMessage(message)
//        }

//        public func session(_: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
//            getMessage(userInfo)
//        }
//
//        public func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
//            getMessage(applicationContext)
//        }
        
        public func session(_ session: WCSession, didReceive file: WCSessionFile) {
            getFile(file: file)
        }
        
        public func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
            guard !fileTransfer.file.fileURL.isiCloud else { return }
            if let error = error {
                print("❌ Dateiübertragung fehlgeschlagen: \(error.localizedDescription)")
            } else {
                print("✅ Datei erfolgreich übertragen: \(fileTransfer.file.fileURL.lastPathComponent)")

                // Aufräumen:
                do {
                    try FileManager.default.removeItem(at: fileTransfer.file.fileURL)
                    print("🧹 Temp-Datei gelöscht.")
                } catch {
                    print("⚠️ Fehler beim Löschen der Datei: \(error)")
                }
            }
        }

        #if os(iOS)
            public func sessionDidDeactivate(_ session: WCSession) {
                log.log("sessionDidDeactivate")
                session.activate()
            }

            public func sessionDidBecomeInactive(_: WCSession) {
                log.log("sessionDidBecomeInactive")

//                session.activate()
            }
        #endif
    }
#endif
