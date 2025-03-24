//
//  CoordinatorPersistentContainer.swift
//  Smaug
//
//  Created by Guido Kühn on 23.03.25.
//


import WatchConnectivity

protocol CoordinatorPersistentContainer: AnyObject {
        func receiveData(data: Data)
        func showData() -> Data?
        var identifier: String { get }
    }