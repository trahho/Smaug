//
//  Test.swift
//  Smaug
//
//  Created by Guido Kühn on 18.10.25.
//

import Foundation
import Testing

struct Test {
    @Test func hourTest() async throws {
        print("\(Date.now) -> \(Date.now.begin(of: .hour))")
    }

//    @Test func dayTest() async throws {
//        print("\(Date.now) -> \(Date.now.begin(of: .day))")
//    }
}
