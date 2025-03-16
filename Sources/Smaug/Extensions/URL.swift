//
//  URL+virtual.swift
//  Hippocampus (iOS)
//
//  Created by Guido Kühn on 02.12.22.
//

import Foundation

public extension URL {
    var isVirtual: Bool {
        scheme == "virtual"
    }

    var isLocal: Bool {
        absoluteString.hasPrefix(URL.localDirectory.absoluteString)
    }

    var isiCloud: Bool {
        absoluteString.hasPrefix(URL.iCloudDirectory.absoluteString)
    }

    static var virtual: URL {
        URL(string: "virtual:///")!
    }

    static var iCloudDirectory: URL {
        FileManager.default.url(forUbiquityContainerIdentifier: nil) ?? virtual
    }

    static var localDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var iCloudContainerUrl: URL { URL.iCloudDirectory.appendingPathComponent("Documents") }

    static var localContainerUrl: URL { URL.localDirectory }

    func startDownloading() {
        guard isiCloud else { return }
        try? FileManager.default.startDownloadingUbiquitousItem(at: self)
    }

    func appending(pathComponents: [String]) -> URL {
        var result = self
        pathComponents.forEach { result.append(component: $0) }
        return result
    }

    func ensureDirectory() {
        guard hasDirectoryPath else { return }
        let directory = path(percentEncoded: false)
        if !FileManager.default.fileExists(atPath: directory) {
            try! FileManager.default.createDirectory(at: self, withIntermediateDirectories: true)
        }
    }
}
