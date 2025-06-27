//
//  PersistentContainer.swift
//  Hippocampus
//
//  Created by Guido Kühn on 26.02.23.
//

import Combine
import Foundation

#if os(watchOS) || os(iOS)
    extension PersistentContainer: CoordinatorPersistentContainer {
        public func showFileURL() -> URL? {
            url
        }

        public func receiveFileURL(_ url: URL) {
            print("Receive File")
            guard
                var data = try? Data(contentsOf: url, options: [.uncached]) // ,
//                let newContent = unstamped(data: data)
            //                ,
            //            let newContent = Content.decode(persistentData: data)
            else { return }
            data.removeSubrange(0 ..< timestampStringLength)

            guard
                let data = try? (data as NSData).decompressed(using: .lzfse) as Data,
                let newContent = Content.decode(persistentData: data)
            else { return }
//            guard let data = try? Data(contentsOf: url),
//                  let data = try? (data as NSData).decompressed(using: .lzfse) as Data,
//                  let newContent = Content.decode(persistentData: data)
//            else { return }
            restore(content: newContent)
            update(with: newContent)
            hasChanges = true
            save(isReceiving: true)
        }

        public func receiveData(data: Data) {
            print("Receive Data")

            guard let data = try? (data as NSData).decompressed(using: .lzfse) as Data,
                  let newContent = Content.decode(persistentData: data)
            else { return }
//            lock.withLock {
//                print("Lock acquired")
            restore(content: newContent)
            update(with: newContent)
            hasChanges = true
//            }
            save()
        }

        public var identifier: String {
            key
        }

        public func showData() -> Data? {
            guard
                let data = content.encode(),
                let data = try? (data as NSData).compressed(using: .lzfse) as Data
            else { return nil }
            return data
        }

        func sendData() {
            print("Send Data")
            WatchCoordinator.shared.sendFile(container: self)
        }
    }
#endif
public class PersistentContainer<Content: PersistentContent> /*: ObservableObject */ {
    // MARK: Nested Types

    typealias ContentDelegate = () -> Void

    // MARK: Properties

    let url: URL
    let key: String
    var contentChange: ContentDelegate?
    var willCommit: (() -> Void)?
    var commitOnChange = false
    private(set) var hasChanges = false

    private let timestampStringLength = 30

    private var lock = NSLock()
    private var isMerging = false
    private var isReceiving = false
    private var currentFileTimestamp: Date = .distantPast
    private var currentDataTimestamp: Double = 0
    #if !os(watchOS)
        private let metadataQuery = NSMetadataQuery()
        private var querySubscriber: AnyCancellable?
    #endif
    private var didChangeSubcriber: AnyCancellable?
    private var willChangeSubscriber: AnyCancellable?

    private var _content: Content?

    // MARK: Computed Properties

    var content: Content {
        get { _content! }
        set {
            let hasChange = _content != nil
            setContent(newValue)
            if hasChange, commitOnChange {
                hasChanges = true
                save()
                hasChanges = false
            } else {
                hasChanges = true
            }
        }
    }

    // MARK: Lifecycle

    init(url: URL, content: Content, commitOnChange: Bool = false, configureContent: ContentDelegate? = nil) {
        if url.isiCloud {
            url.deletingLastPathComponent().startDownloading()
            key = String(url.path.dropFirst(URL.iCloudContainerUrl.path.count))
        } else {
            key = String(url.path.dropFirst(URL.localContainerUrl.path.count))
        }

        self.url = url
        self.commitOnChange = commitOnChange
        contentChange = configureContent
        restore(content: content)
        setContent(content)
        #if os(watchOS) || os(iOS)
            WatchCoordinator.shared.registerContainer(container: self)
        #endif
    }

    #if !os(watchOS)
        deinit {
            guard metadataQuery.isStarted else { return }
            metadataQuery.stop()
        }
    #endif

    // MARK: Functions

    public func save(isReceiving: Bool = false) {
        let fileQueue = DispatchQueue(label: "de.kuehnerleben.smaug.file", qos: .background)
        guard !url.isVirtual, hasChanges else { return }
        fileQueue.async { [self] in
//            lock.withLock { [weak self] in
//            guard let self = self else { return }
            //            #if TRACKPERSISTENCE
            print("PersistentDataContainer<\(String(reflecting: Content.self))>: Save")
            //            #endif

//            willCommit?()
            guard let data = self.stamped(content: self.content) else { return }

            #if !os(watchOS)
                metadataQuery.stop()
            #endif
            self.url.deletingLastPathComponent().ensureDirectory()

            //            #if TRACKPERSISTENCE
            //                measureDuration("Write data") {
            //                    try! data.write(to: url, options: [.atomic])
            //                }
            //            #else
            try! data.write(to: url, options: [.atomic])
            //            #endif

            currentFileTimestamp = try! FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as! Date

            //            #if TRACKPERSISTENCE
            print("Modified \(currentFileTimestamp)")
            //            #endif

            hasChanges = false

            #if !os(watchOS)

//                DispatchQueue.main.sync {
//                    //                #if TRACKPERSISTENCE
//                    print("Reactivating query")
//                    //                #endif
                    metadataQuery.start()
//                }
            #endif
            #if os(watchOS) || os(iOS)
                if !isReceiving { sendData() }
            #endif
            //            #if TRACKPERSISTENCE
            print("Done")
            //            #endif
//            }
        }
    }

    public func load() {
        lock.withLock {
            guard !url.isVirtual else { return }
            guard
                let modificationDate = try? FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))[.modificationDate] as? Date,
                modificationDate > currentFileTimestamp
            else {
                if url.isiCloud { url.deletingLastPathComponent().startDownloading() }
                return
            }
            guard
                let data = try? Data(contentsOf: url, options: [.uncached]),
                let newContent = unstamped(data: data)
            //                ,
            //            let newContent = Content.decode(persistentData: data)
            else { return }

            //        #if TRACKPERSISTENCE
            print("PersistentDataContainer<\(String(reflecting: Content.self))>: Load \(url.absoluteString)")
            //        #endif

            restore(content: newContent)
            update(with: newContent)

            currentFileTimestamp = modificationDate
            hasChanges = false

            //        #if TRACKPERSISTENCE
            print("Updated \(currentFileTimestamp)")
            //        #endif
            #if os(watchOS) || os(iOS)
                sendData()
            #endif
        }
    }

    func stamped(content: Content) -> Data? {
        guard
            let data = content.encode(),
            let data = try? (data as NSData).compressed(using: .lzfse) as Data
        else { return nil }
        currentDataTimestamp = Date().timeIntervalSince1970
        let string = String(currentDataTimestamp)
        let stampString = string + String(repeating: "0", count: timestampStringLength - string.count)
        var stampedData = stampString.data(using: .ascii)
        stampedData?.append(data)
        return stampedData
    }

    func restore(content: Content) {
        if let restorable = content as? Restorable {
            restorable.restore()
        }
    }

    func unstamped(data: Data?) -> Content? {
        guard var data else { return nil }

        let stampData = data.subdata(in: 0 ..< timestampStringLength)
        guard
            let stampString = String(data: stampData, encoding: .ascii),
            let dataTimestamp = Double(stampString),
            dataTimestamp > currentDataTimestamp
        else { return nil }
        data.removeSubrange(0 ..< timestampStringLength)

        guard
            let data = try? (data as NSData).decompressed(using: .lzfse) as Data,
            let content = Content.decode(persistentData: data)
        else { return nil }

        currentDataTimestamp = dataTimestamp
        return content
    }

    func start() {
        #if !os(watchOS)
            setupMetadataQuery()
        #endif
    }

//    func contentDidChange() {
//        if commitOnChange {
//            hasChanges = true
//            save()
//            hasChanges = false
//        } else {
//            hasChanges = true
//        }
//    }

    fileprivate func setContent(_ newValue: Content) {
//        objectWillChange.send()
        _content = newValue
        if _content != nil {
            if let contentChange {
                contentChange()
            }
        }
        registerChanges()
    }

    fileprivate func registerChanges() {
        guard let _content else { return }
        didChangeSubcriber = _content.objectDidChange
            .filter { !self.isMerging }
            .debounce(for: .seconds(1.5), scheduler: RunLoop.main)
            .sink { [self] in
                guard !isMerging else { return }
                #if os(watchOS) || os(iOS)
                    sendData()
                #endif
                if commitOnChange {
                    hasChanges = true
                    save()
                    hasChanges = false
                } else {
                    hasChanges = true
                }
            }

//        if let content = _content as? (any ObservableObject), let publisher = (content.objectWillChange as any Publisher) as? (ObservableObjectPublisher) {
//            willChangeSubscriber = publisher
//                .sink { [self] in
        ////                    self.objectWillChange.send()
//                    hasChanges = true
//                }
//        } else {
//            willChangeSubscriber?.cancel()
//            willChangeSubscriber = nil
//        }
    }

    fileprivate func update(with newContent: Content) {
        if let newContent = newContent as? Mergeable, var content = content as? Mergeable {
            do {
                isMerging = true
                try content.merge(other: newContent)
                isMerging = false
            } catch {}
        } else {
            setContent(newContent)
        }
    }

    #if !os(watchOS)
        fileprivate func setupMetadataQuery() {
            guard !url.isVirtual else { return }

            let names: [NSNotification.Name] = [.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate]
            let publishers = names.map { NotificationCenter.default.publisher(for: $0) }

            querySubscriber = Publishers.MergeMany(publishers)
                .receive(on: DispatchQueue.main)
                .filter {
                    if let query = $0.object as? NSMetadataQuery, query == self.metadataQuery {
                        true
                    } else {
                        false
                    }
                }
                .sink { [self] _ in
                    self.load()
                }

            metadataQuery.notificationBatchingInterval = 0.1 // .1

            if url.isiCloud {
                metadataQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
            } else {
                #if os(iOS)
                    metadataQuery.searchScopes = [NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
                #endif
                #if os(macOS)
                    metadataQuery.searchScopes = [NSMetadataQueryLocalComputerScope]
                #endif
            }

            let pathPredicate = NSComparisonPredicate(leftExpression: NSExpression(forConstantValue: url.path(percentEncoded: false)),
                                                      rightExpression: NSExpression(forKeyPath: NSMetadataItemPathKey),
                                                      modifier: .direct,
                                                      type: .beginsWith)
            metadataQuery.predicate = pathPredicate
            metadataQuery.start()
            metadataQuery.enableUpdates()
        }
    #endif
}
