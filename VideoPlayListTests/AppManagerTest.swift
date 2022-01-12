import XCTest

class AppManagerTest: XCTestCase {

    let appManager = AppManager()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    //
    // MARK: Photo access
    //

    func test_isAuthorized() throws {
        XCTAssertTrue(appManager.isAuthorized(authStatus: .authorized))
        XCTAssertFalse(appManager.isAuthorized(authStatus: .notDetermined))
        XCTAssertFalse(appManager.isAuthorized(authStatus: .restricted))
        XCTAssertFalse(appManager.isAuthorized(authStatus: .denied))
        XCTAssertFalse(appManager.isAuthorized(authStatus: .limited))
    }

    //
    // MARK: App control
    //

    func test_createNavigationTitle() throws {
        var message: String
        var model: Model
        message = appManager.createNavigationTitle(model: Model())
        XCTAssertTrue(message == "ビデオアルバム無し" || message == "No Video Albums")

        model = Model(albums: [
            PreviewAlbum(id: "1", title: "1", videos: []),
            PreviewAlbum(id: "2", title: "2", videos: []),
        ])
        message = appManager.createNavigationTitle(model: model)
        XCTAssertTrue(message == "ビデオアルバム (2)" || message == "Video Albums (2)")
    }
    
    //
    // MARK: Player control
    //
    

    func test_openAlbum() throws {
        SettingsManager.sharedManager.settings = Settings()
        
        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        let requestPlayStart = appManager.requestPlayStart
        let requestCloseAlbum = appManager.requestCloseAlbum
        let requestPausePlay = appManager.requestPausePlay
        let requestRestartPlay = appManager.requestRestartPlay
        appManager.openAlbum(album: album)
        XCTAssertEqual(0, appManager.rotationAngle)
        XCTAssertEqual(false, appManager.pausePlayFlag)
        XCTAssertEqual("a1", appManager.mediaManager.getAlbum()?.id)
        XCTAssertEqual(0, appManager.mediaManager.getPlayIndex())
        XCTAssertEqual("v1", appManager.getCurrentVideo()?.id)
        XCTAssertNotEqual(requestPlayStart, appManager.requestPlayStart) // play flag更新
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)

    }
    
    func test_getCurrentVideo() throws {
        var album: Album

        XCTAssertNil(appManager.getCurrentVideo())

        // Albumを設定
        album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album)
        XCTAssertEqual("v1", appManager.getCurrentVideo()?.id)

        // 空のAlbumを設定
        album = PreviewAlbum(id: "a1", title: "title1", videos: [])
        appManager.openAlbum(album: album)
        XCTAssertNil(appManager.getCurrentVideo())
    }

    func test_timerHideNavigationBar() throws {
        var requestPlayStart = appManager.requestPlayStart
        var requestCloseAlbum = appManager.requestCloseAlbum
        var requestPausePlay = appManager.requestPausePlay
        var requestRestartPlay = appManager.requestRestartPlay

        var expect: XCTestExpectation
        var timer: Timer

        // ビデオ再生中
        appManager.pausePlayFlag = false
        appManager.hideNavigationBar = false
        self.appManager.timerHideNavigationBar()

        // NavigationBarが非表示になるまで待機
        expect = expectation(description: "async test")
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            if self.appManager.hideNavigationBar {
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 3)
        timer.invalidate()
        // フラグは変化しない
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)

        // ビデオ停止中
        requestPlayStart = appManager.requestPlayStart
        requestCloseAlbum = appManager.requestCloseAlbum
        requestPausePlay = appManager.requestPausePlay
        requestRestartPlay = appManager.requestRestartPlay
        appManager.pausePlayFlag = true
        appManager.hideNavigationBar = false
        appManager.timerHideNavigationBar()

        // 一定時間待機
        expect = expectation(description: "async test")
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (timer) in
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5)
        timer.invalidate()

        // 一定時間経過してもNavigationBarが非表示にならない
        XCTAssertEqual(false, appManager.hideNavigationBar)
        // フラグは変化しない
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)

    }

    func test_closeAlbum() {
        let requestPlayStart = appManager.requestPlayStart
        let requestCloseAlbum = appManager.requestCloseAlbum
        let requestPausePlay = appManager.requestPausePlay
        let requestRestartPlay = appManager.requestRestartPlay
        appManager.closeAlbum()
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertNotEqual(requestCloseAlbum, appManager.requestCloseAlbum) // close flag更新
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)
    }

    func test_startPlay() {
        let requestPlayStart = appManager.requestPlayStart
        let requestCloseAlbum = appManager.requestCloseAlbum
        let requestPausePlay = appManager.requestPausePlay
        let requestRestartPlay = appManager.requestRestartPlay

        appManager.pausePlayFlag = true
        appManager.startPlay()
        XCTAssertEqual(false, appManager.pausePlayFlag)
        XCTAssertNotEqual(requestPlayStart, appManager.requestPlayStart) // play flag更新
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)

        // NavigationBarが非表示になるまで待機
        let expect = expectation(description: "async test")
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            if self.appManager.hideNavigationBar {
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 3)
        timer.invalidate()
    }
    
    func test_nextPlay() {
        var requestPlayStart = appManager.requestPlayStart
        var requestCloseAlbum = appManager.requestCloseAlbum
        var requestPausePlay = appManager.requestPausePlay
        var requestRestartPlay = appManager.requestRestartPlay

        // Album無しで実施した場合はcloseする
        appManager.nextPlay()
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertNotEqual(requestCloseAlbum, appManager.requestCloseAlbum) // close flag更新
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album)

        // 0 => 1
        requestPlayStart = appManager.requestPlayStart
        requestCloseAlbum = appManager.requestCloseAlbum
        requestPausePlay = appManager.requestPausePlay
        requestRestartPlay = appManager.requestRestartPlay
        appManager.nextPlay()
        XCTAssertNotEqual(requestPlayStart, appManager.requestPlayStart) // start flag更新
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)

        // 1 => 2
        requestPlayStart = appManager.requestPlayStart
        requestCloseAlbum = appManager.requestCloseAlbum
        requestPausePlay = appManager.requestPausePlay
        requestRestartPlay = appManager.requestRestartPlay
        appManager.nextPlay()
        XCTAssertNotEqual(requestPlayStart, appManager.requestPlayStart) // start flag更新
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)

        // 2 => close
        requestPlayStart = appManager.requestPlayStart
        requestCloseAlbum = appManager.requestCloseAlbum
        requestPausePlay = appManager.requestPausePlay
        requestRestartPlay = appManager.requestRestartPlay
        appManager.nextPlay()
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertNotEqual(requestCloseAlbum, appManager.requestCloseAlbum) // close flag更新
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)
    }
    
    func test_previousPlay() {
        var requestPlayStart = appManager.requestPlayStart
        var requestCloseAlbum = appManager.requestCloseAlbum
        var requestPausePlay = appManager.requestPausePlay
        var requestRestartPlay = appManager.requestRestartPlay

        // Album無しで実施した場合は何も起きない
        appManager.previousPlay()
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album)

        // 0 => 1
        appManager.nextPlay()

        // 1 => 0
        requestPlayStart = appManager.requestPlayStart
        requestCloseAlbum = appManager.requestCloseAlbum
        requestPausePlay = appManager.requestPausePlay
        requestRestartPlay = appManager.requestRestartPlay
        appManager.previousPlay()
        XCTAssertNotEqual(requestPlayStart, appManager.requestPlayStart) // start flag更新
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)

        // 0 => 0 何も起きない
        requestPlayStart = appManager.requestPlayStart
        requestCloseAlbum = appManager.requestCloseAlbum
        requestPausePlay = appManager.requestPausePlay
        requestRestartPlay = appManager.requestRestartPlay
        appManager.previousPlay()
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)
    }
    
    func test_pausePlay() {
        var requestPlayStart = appManager.requestPlayStart
        var requestCloseAlbum = appManager.requestCloseAlbum
        var requestPausePlay = appManager.requestPausePlay
        var requestRestartPlay = appManager.requestRestartPlay

        // Album無しでもPauseできる
        appManager.pausePlay()
        XCTAssertEqual(false, appManager.hideNavigationBar)
        XCTAssertEqual(true, appManager.pausePlayFlag)
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertNotEqual(requestPausePlay, appManager.requestPausePlay) // pause flag更新
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)
        
        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album)

        // Pause
        requestPlayStart = appManager.requestPlayStart
        requestCloseAlbum = appManager.requestCloseAlbum
        requestPausePlay = appManager.requestPausePlay
        requestRestartPlay = appManager.requestRestartPlay
        appManager.pausePlay()
        XCTAssertEqual(false, appManager.hideNavigationBar)
        XCTAssertEqual(true, appManager.pausePlayFlag)
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertNotEqual(requestPausePlay, appManager.requestPausePlay) // pause flag更新
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)
    }

    func test_restartPlay() {
        var requestPlayStart = appManager.requestPlayStart
        var requestCloseAlbum = appManager.requestCloseAlbum
        var requestPausePlay = appManager.requestPausePlay
        var requestRestartPlay = appManager.requestRestartPlay

        // Album無しでRestartしても何も起きない
        appManager.restartPlay()
        XCTAssertEqual(false, appManager.pausePlayFlag)
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album)
        
        // 再生中にrestartしても何も起きない
        requestPlayStart = appManager.requestPlayStart
        requestCloseAlbum = appManager.requestCloseAlbum
        requestPausePlay = appManager.requestPausePlay
        requestRestartPlay = appManager.requestRestartPlay
        appManager.restartPlay()
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)
        
        // Pause
        appManager.pausePlay()

        // Restart
        requestPlayStart = appManager.requestPlayStart
        requestCloseAlbum = appManager.requestCloseAlbum
        requestPausePlay = appManager.requestPausePlay
        requestRestartPlay = appManager.requestRestartPlay
        appManager.restartPlay()
        XCTAssertEqual(false, appManager.pausePlayFlag)
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertNotEqual(requestRestartPlay, appManager.requestRestartPlay) // restart flag更新

        // NavigationBarが非表示になるまで待機
        let expect = expectation(description: "async test")
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            if self.appManager.hideNavigationBar {
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 3)
        timer.invalidate()
    }
    
    func test_togglePauseAndRestartPlay() {
        let requestPlayStart = appManager.requestPlayStart
        let requestCloseAlbum = appManager.requestCloseAlbum
        let requestPausePlay = appManager.requestPausePlay
        let requestRestartPlay = appManager.requestRestartPlay

        // Album無しでtoggleしても何も起きない
        appManager.togglePauseAndRestartPlay()
        XCTAssertEqual(false, appManager.pausePlayFlag)
        XCTAssertEqual(requestPlayStart, appManager.requestPlayStart)
        XCTAssertEqual(requestCloseAlbum, appManager.requestCloseAlbum)
        XCTAssertEqual(requestPausePlay, appManager.requestPausePlay)
        XCTAssertEqual(requestRestartPlay, appManager.requestRestartPlay)
        
        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album)

        // play => pause
        appManager.togglePauseAndRestartPlay()
        XCTAssertEqual(true, appManager.pausePlayFlag)

        // pause => play
        appManager.togglePauseAndRestartPlay()
        XCTAssertEqual(false, appManager.pausePlayFlag)
    }
    
}
