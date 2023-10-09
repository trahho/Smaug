//
//  PersistentContainer.swift
//  Hippocampus
//
//  Created by Guido Kühn on 26.02.23.
//

import Combine
import Foundation

public class PersistentContainer<Content: Persistent>: ObservableObject {
    typealias ContentDelegate = () -> Void

    let url: URL
    private var isMerging = false
    private var currentTimestamp: Date = .distantPast
    private let metadataQuery = NSMetadataQuery()
    private var querySubscriber: AnyCancellable?
    private var didChangeSubcriber: AnyCancellable?
    private var willChangeSubscriber: AnyCancellable?

    var contentChange: ContentDelegate?
    var willCommit: (() -> Void)?
    var commitOnChange = false
    private(set) var hasChanges = false

    private var _content: Content?
    var content: Content {
        get { _content! }
        set {
            objectWillChange.send()
            _content = newValue
            if _content != nil, let contentChange { contentChange() }
            registerChanges()
        }
    }

    fileprivate func registerChanges() {
        guard let _content else { return }
        didChangeSubcriber = _content.objectDidChange
            .debounce(for: .seconds(1.5), scheduler: RunLoop.main)
            .sink { [self] in
                guard !isMerging else { return }
                if commitOnChange {
                    hasChanges = true
                    save()
                    hasChanges = false
                } else {
                    hasChanges = true
                }
            }

        if let content = _content as? (any ObservableObject), let publisher = (content.objectWillChange as any Publisher) as? (ObservableObjectPublisher) {
            willChangeSubscriber = publisher
                .sink { [self] in
                    self.objectWillChange.send()
                    hasChanges = true
                }
        } else {
            willChangeSubscriber?.cancel()
            willChangeSubscriber = nil
        }
    }

    public func save() {
        let fileQueue = DispatchQueue(label: "de.kuehnerleben.Hippocampus.file", qos: .background)
        guard !url.isVirtual, hasChanges else { return }
        fileQueue.async { [self] in
            #if TRACKPERSISTENCE
                print("PersistentDataContainer<\(String(reflecting: Content.self))>: Save")
            #endif

            willCommit?()
            guard let data = content.encode() else { return }
            metadataQuery.stop()
            url.deletingLastPathComponent().ensureDirectory()

            #if TRACKPERSISTENCE
                measureDuration("Write data") {
                    try! data.write(to: url, options: [.atomic])
                }
            #else
                try! data.write(to: url, options: [.atomic])
            #endif

            currentTimestamp = try! FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as! Date

            #if TRACKPERSISTENCE
                print("Modified \(currentTimestamp)")
            #endif

            hasChanges = false
            DispatchQueue.main.sync {
                #if TRACKPERSISTENCE
                    print("Reactivating query")
                #endif
                metadataQuery.start()
            }
            #if TRACKPERSISTENCE
                print("Done")
            #endif
        }
    }

    fileprivate func updateContent(_ newContent: Content) {
        if let newContent = newContent as? Mergeable, let content = content as? Mergeable {
            do {
                isMerging = true
                try content.merge(other: newContent)
                isMerging = false
            } catch {}
        }
        content = newContent
    }

    func restore(content: Content) {
        if let restorable = content as? Restorable {
            restorable.restore()
        }
    }

    public func load() {
        guard !url.isVirtual else { return }
        guard
            let modificationDate = try? FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))[.modificationDate] as? Date,
            modificationDate > currentTimestamp
        else {
            if url.isiCloud { url.deletingLastPathComponent().startDownloading() }
            return
        }
        guard
            let data = try? Data(contentsOf: url, options: [.uncached]),
            let newContent = Content.decode(persistentData: data)
        else { return }

        #if TRACKPERSISTENCE
            print("PersistentDataContainer<\(String(reflecting: Content.self))>: Load")
        #endif

        restore(content: newContent)
        updateContent(newContent)

        currentTimestamp = modificationDate
        hasChanges = false

        #if TRACKPERSISTENCE
            print("Updated \(currentTimestamp)")
        #endif
    }

    fileprivate func setupMetadataQuery() {
        guard !url.isVirtual else { return }

        let names: [NSNotification.Name] = [.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate]
        let publishers = names.map { NotificationCenter.default.publisher(for: $0) }

        querySubscriber = Publishers.MergeMany(publishers)
            .receive(on: DispatchQueue.main)
            .sink { [self] notification in
                guard let query = notification.object as? NSMetadataQuery, query === self.metadataQuery else { return }
//                let items = query.results.compactMap { $0 as? NSMetadataItem }//.filter { $0.value(forAttribute: nsmetdata) as! Bool == false }
                query.disableUpdates()
                self.load()
                query.enableUpdates()
            }

        metadataQuery.notificationBatchingInterval = 0 // .1

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

    init(url: URL, content: Content, commitOnChange: Bool = false, configureContent: ContentDelegate? = nil) {
        if url.isiCloud {
            url.deletingLastPathComponent().startDownloading()
        }
        self.url = url
        self.commitOnChange = commitOnChange
        self.contentChange = configureContent
        restore(content: content)
        self.content = content
    }

    func start() {
        setupMetadataQuery()
    }

    deinit {
        guard metadataQuery.isStarted else { return }
        metadataQuery.stop()
    }
}
