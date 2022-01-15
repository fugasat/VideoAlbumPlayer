//
//  MediaUtilityTests.swift
//  VideoPlayListTests
//
//  Created by Satoru on 2022/01/15.
//

import XCTest

class MediaUtilityTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_isAuthorized() throws {
        let mediaUtility = MediaUtility()
        XCTAssertTrue(mediaUtility.isAuthorized(authStatus: .authorized))
        XCTAssertFalse(mediaUtility.isAuthorized(authStatus: .notDetermined))
        XCTAssertFalse(mediaUtility.isAuthorized(authStatus: .restricted))
        XCTAssertFalse(mediaUtility.isAuthorized(authStatus: .denied))
        XCTAssertFalse(mediaUtility.isAuthorized(authStatus: .limited))
    }


}
