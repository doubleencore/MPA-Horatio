//
//  ContainerTest.swift
//  HoratioTests
//
//  Created by Kyle Watson on 4/23/18.
//  Copyright © 2018 Mudpot Apps. All rights reserved.
//

import XCTest
@testable import Horatio

// Note - Not testing static methods
class ContainerTest: XCTestCase {
    
    class TestObject: Equatable {
        let s: String
        init(_ s: String) { self.s = s }
        static func ==(lhs: TestObject, rhs: TestObject) -> Bool {
            return lhs.s == rhs.s
        }
    }
    
    var sut: Container!
    
    override func setUp() {
        super.setUp()
        
        sut = Container()
    }
    
    /*
     Because `services` is private (as it should be), it may be worthwhile to add
     an `isRegistered(T.type, named: String)` method to the public API. It would
     be thread-safe.
     */
    func testRegisterReturnsCorrectEntry() {
        
        // arrange
        let factory: (Resolvable) -> TestObject = { _ in TestObject("some random string") }
        
        // act
        let entry = sut.register(TestObject.self, factory: factory)
        
        // assert
        let result = (entry.factory as! ((Resolvable) -> TestObject))
        XCTAssertEqual(factory(sut), result(sut))
    }

    // TODO: The next 3 tests do not really test anything else in the register
    // method.
    // FIXME: this doesn't really test anything...
//    func testRegisterWithNameReturnsCorrectEntry() {
//
//        let factories: [String: ((Resolvable) -> TestObject)] = [
//            "first": { _ in TestObject("first string") },
//            "second": { _ in TestObject("second string") }
//        ]
//
//        let firstEntry = sut.register(TestObject.self, name: "first", factory: factories["first"]!)
//        let secondEntry = sut.register(TestObject.self, name: "second", factory: factories["second"]!)
//
//        let firstRegisteredFactory = (firstEntry.factory as! ((Resolvable) -> TestObject))
//        XCTAssertEqual(factories["first"]!(sut), firstRegisteredFactory(sut))
//
//        let secondRegisteredFactory = (secondEntry.factory as! ((Resolvable) -> TestObject))
//        XCTAssertEqual(factories["second"]!(sut), secondRegisteredFactory(sut))
//    }
    
    // FIXME: this doesn't really test anything...
//    func testRegisterMultipleTimesReturnsTheLastEntry() {
//
//        let lastFactory: (Resolvable) -> TestObject = { _ in TestObject("this is the correct string!") }
//
//        _ = sut.register(TestObject.self, factory: { _ in TestObject("blah") })
//        _ = sut.register(TestObject.self, factory: { _ in TestObject("another blah") })
//        let lastEntry = sut.register(TestObject.self, factory: lastFactory)
//
//        let result = (lastEntry.factory as! ((Resolvable) -> TestObject))
//        XCTAssertEqual(lastFactory(sut), result(sut))
//    }
    
    // FIXME: this doesn't really test anything...
//    func testRegisterFactoryUsesOtherFactory() {
//
//        let stringToUse = "some String to use!"
//        _ = sut.register(String.self) { _ in stringToUse }
//
//        let entry = sut.register(TestObject.self) { (resolvable) in
//            let resolvedString = resolvable.resolve(String.self, name: nil)!
//            return TestObject(resolvedString)
//        }
//
//        let result = (entry.factory as! ((Resolvable) -> TestObject))
//        XCTAssertEqual(TestObject(stringToUse), result(sut))
//    }

    
    // You can see this fail by commenting servicesLock in the resolveFactory method
    func testRegisterIsThreadsafe() {
        
        let count = 50
        
        let dispatchGroup = DispatchGroup()
        let concurrentQueue = DispatchQueue(label: "ConcurrentTestQueue", attributes: .concurrent)
        let arrayLock = NSLock()
        
        var entries = [ContainerEntry<TestObject>]()
        
        for i in 0..<count {
            dispatchGroup.enter()
            
            concurrentQueue.async { [sut] in
                let entry = sut!.register(TestObject.self, name: "\(i)", factory: { _ in TestObject("some string \(i)") })
                
                arrayLock.lock()
                entries.append(entry)
                arrayLock.unlock()
                
                dispatchGroup.leave()
            }
        }
        
        let expect = expectation(description: "concurrent register expectation")
        
        dispatchGroup.notify(queue: .main) {
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 1.0) { (error) in
            XCTAssert(entries.count == count)
        }
    }
    
    func testResolveReturnsCorrectFactoryObject() {
        
        let testObject = TestObject("some string")
        _ = sut.register(TestObject.self, factory: { _ in testObject })
        
        let resolvedObject = sut.resolve(TestObject.self)
        
        XCTAssertEqual(testObject, resolvedObject)
    }
    
    func testResolveUsingNameReturnsCorrectFactoryObject() {
        
        let firstTestObject = TestObject("first string")
        let secondTestObject = TestObject("second string")
        
        _ = sut.register(TestObject.self, name: "first", factory: { _ in firstTestObject })
        _ = sut.register(TestObject.self, name: "second", factory: { _ in secondTestObject })
        
        let firstResolvedObject = sut.resolve(TestObject.self, name: "first")
        XCTAssertEqual(firstTestObject, firstResolvedObject)
        
        let secondResolvedObject = sut.resolve(TestObject.self, name: "second")
        XCTAssertEqual(secondTestObject, secondResolvedObject)
    }
    
    func testResolveWithMultipleRegisterReturnsLastEntry() {
        
        let lastTestObject = TestObject("last test object")
        _ = sut.register(TestObject.self, factory: { _ in TestObject("blah") })
        _ = sut.register(TestObject.self, factory: { _ in TestObject("blah again") })
        _ = sut.register(TestObject.self, factory: { _ in lastTestObject })
        
        let resolvedTestObject = sut.resolve(TestObject.self)
        
        XCTAssertEqual(lastTestObject, resolvedTestObject)
    }
    
    func testResolveFactoryUsesDependencyFactory() {
        let stringToUse = "some String to use!"
        _ = sut.register(String.self) { _ in stringToUse }
        _ = sut.register(TestObject.self) { (resolvable) in
            let resolvedString = resolvable.resolve(String.self, name: nil)!
            return TestObject(resolvedString)
        }
        
        let resolvedTestObject = sut.resolve(TestObject.self)
        
        XCTAssertEqual(TestObject(stringToUse), resolvedTestObject)
    }
    
    func testResolveIsThreadSafe() {
        // this only seems testable if I can remove services. I will look into
        // testing this more when it is not so late.
    }
}
