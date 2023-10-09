//
//  DataStoreTests.swift
//
//
//  Created by Guido Kühn on 05.05.23.
//

import XCTest

final class DataStoreTests: XCTestCase {
    func serialize(doc: Document) {
        let dataA = try! JSONEncoder().encode(doc.$a.content)
        doc.$a.content = try! JSONDecoder().decode(A.self, from: dataA)

        let dataB = try! JSONEncoder().encode(doc.$b.content)
        doc.$b.content = try! JSONDecoder().decode(B.self, from: dataB)
    }

    func testInit() throws {
        let doc = Document(url: .virtual)
        let a = A.A()
        doc.add(a)
//        serialize(doc: doc)

        let a1 = doc[A.A.self, a.id]!
        XCTAssertEqual(a1, a)
    }

    func testProperty() throws {
        let doc = Document(url: .virtual)
        let a = A.A()
        doc.add(a)
        a.s = "Hallo Welt"
        serialize(doc: doc)

        XCTAssertEqual(a.s, "Hallo Welt")

        let a1 = doc[A.A.self, a.id]!
        XCTAssertEqual(a1.s, a.s)
    }

    func testObject() throws {
        let doc = Document(url: .virtual)
        let a = A.A()
        let b = B.B()
        doc.add(a)
        doc.add(b)
        a.b = b
        serialize(doc: doc)

        XCTAssertNotNil(doc[B.B.self, b.id])
        XCTAssertEqual(a.b, b)
    }

    func testReverse() throws {
        let doc = Document(url: .virtual)
        let a = A.A()
        let b = B.B()
        doc.add(a)
        doc.add(b)
        a.b = b
        serialize(doc: doc)

        XCTAssertEqual(b.a, a)
    }

    func testReverses() throws {
        let doc = Document(url: .virtual)
        let a = A.A()
        let b = B.B()
        b.a1 = a
        doc.add(a)

        serialize(doc: doc)

        XCTAssertEqual(b.a1, a)
        XCTAssert(a.bb.contains(b))
        XCTAssert(b.aa.contains(a))
    }

    func testAdopt() throws {
        let doc = Document(url: .virtual)
        let a = A.A()
        let b = B.B()
        a.b = b
        doc.add(a)
        XCTAssertNotNil(doc[B.B.self, b.id])
        serialize(doc: doc)
        XCTAssertNotNil(doc[B.B.self, b.id])
    }

    func testSubscript() throws {
        let doc = Document(url: .virtual)
        let a = A.A()
        let b = B.B()
        a.b = b
        doc[] = a
        XCTAssertNotNil(doc[B.B.self, b.id])
        serialize(doc: doc)
        XCTAssertNotNil(doc[B.B.self, b.id])
    }
    
    func testCreate() throws {
        let doc = Document(url: .virtual)
        let a = doc.create(A.A.self)
        let b = doc.create(B.B.self)
        a.b = b
        XCTAssertNotNil(doc[B.B.self, b.id])
        serialize(doc: doc)
        XCTAssertNotNil(doc[B.B.self, b.id])
    }
    
    func testCreateAsFunc() throws {
        let doc = Document(url: .virtual)
        let a = doc(A.A.self)
        let b = doc(B.B.self)
        a.b = b
        XCTAssertNotNil(doc[B.B.self, b.id])
        serialize(doc: doc)
        XCTAssertNotNil(doc[B.B.self, b.id])
    }

    func testTemporary() throws {
        let doc = Document(url: .virtual)
        var _a: A.A! = A.A()
        var _c: C.C! = C.C()
        let id = _c.id
        _c.a = _a
        doc.add(_c)

//        serialize(doc: doc)
        var a = doc[A.A.self, _a.id]
        var c = doc[C.C.self, _c.id]

        XCTAssertNotNil(a)
        XCTAssertNotNil(c)
        XCTAssertEqual(_c, c)
        XCTAssertNotNil(c!.a)
        XCTAssertNotNil(a!.c)

        serialize(doc: doc)

        a!.c = nil
        a = nil
        _a = nil
        _c = nil
        c = nil
        XCTAssertNil(doc[C.C.self, id])
    }
}
