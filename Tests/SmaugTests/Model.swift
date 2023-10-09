//
//  File.swift
//
//
//  Created by Guido Kühn on 05.05.23.
//

import Foundation
import Smaug

class Document: DatabaseDocument {
    @Data var a: A
    @Data var b: B
    @Transient var c: C
}

class A: DataStore<ValueStorage> {
    @Objects var aa: Set<A>
}

class B: DataStore<ValueStorage> {
    @Objects var bb: Set<B>
}

class C: ObjectMemory {
    @Objects var cc: Set<C>
}


extension A {
    class A: Object {
        @Property var s: String
        @Object var b: B.B!
        @Objects var bb: Set<B.B>
        @Relation(\C.C.a) var c: C.C!
    }
}

extension B {
    class B: Object {
        @Property var s: String
        @Relation(\A.A.b) var a: A.A!
        @Relation(\A.A.bb) var a1: A.A!
        @Relations(\A.A.bb) var aa: Set<A.A>
    }
}

extension C {
    class C: Object {
        @Property var s: String
        @Object var a: A.A!
    }
}
