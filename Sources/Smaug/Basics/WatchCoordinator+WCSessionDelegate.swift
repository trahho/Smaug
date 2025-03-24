//
//  WatchCoordinator+WCSessionDelegate.swift
//  Smaug
//
//  Created by Guido Kühn on 23.03.25.
//


import WatchConnectivity

extension WatchCoordinator: WCSessionDelegate {
        public func sessionReachabilityDidChange(_ session: WCSession) {
            log.log("sessionReachabilityDidChange: \(session.isReachable)")
            if session.isReachable {
                onDelay = false
                sendMessage([:])
            } else {
                onDelay = true
            }
        }

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
                sendMessage(delayedMessage)
            } else {
                onDelay = true
            }
        }

        public func session(_: WCSession, didReceiveMessage message: [String: Any]) {
            log.log("didReceiveMessage \(message.count)")
            getMessage(message)
        }

        public func session(_: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
            log.log("didReceiveMessage \(message.count) reply \(delayedMessage.count)")
            replyHandler(delayedMessage)
            getMessage(message)
        }

        public func session(_: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
            getMessage(userInfo)
        }

        public func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
            getMessage(applicationContext)
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
