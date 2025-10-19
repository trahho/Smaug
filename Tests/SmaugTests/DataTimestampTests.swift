////
////  DataTimestampTests.swift
////
////
////  Created by Guido Kühn on 05.01.24.
////
//
//import XCTest
//
//final class DataTimestampTests: XCTestCase {
//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//
//  
//    func testTimestamp() throws {
//        let date = Date()
//        let time: Double = date.timeIntervalSince1970
//        let string = String(time)
//        let string30 = string + String(repeating: "0", count: 30 - string.count)
//        XCTAssert(string30.count == 30)
//        let stringRemoved = string30.filter { $0 != " " }
//        let fromString = Double(stringRemoved)
//        XCTAssert(fromString == time)
//
//        var data = string30.data(using: .ascii)!
//        XCTAssert(data.count == 30)
//        let encoded = try! JSONEncoder().encode(date)
//
//        data.append(encoded)
//
//        let firstData = data.subdata(in: 0 ..< 30)
//        XCTAssert(firstData.count == 30)
//        let decodedTimestampString = String(data: firstData, encoding: .ascii)! // .filter { $0 != " " }
//        let decodedTimestamp = Double(decodedTimestampString)
//        XCTAssert(decodedTimestamp == time)
//
//        data.removeSubrange(0 ..< 30)
//        let decodedDate = try! JSONDecoder().decode(Date.self, from: data)
//        XCTAssert(date == decodedDate)
//    }
//
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
//}
