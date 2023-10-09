//
//  DidChangeNotifier.swift
//  Hippocampus
//
//  Created by Guido Kühn on 02.12.22.
//

import Combine
import Foundation

public protocol DidChangeNotifier {

    typealias ObjectDidChangePublisher = Combine.ObservableObjectPublisher

    var objectDidChange: ObjectDidChangePublisher { get }
}
