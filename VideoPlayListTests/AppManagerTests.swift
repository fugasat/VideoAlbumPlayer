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
        appManager.openAlbum(album: album)
        XCTAssertEqual(0, appManager.rotationAngle)
        XCTAssertEqual("a1", appManager.mediaManager.getAlbum()?.id)
        XCTAssertEqual(0, appManager.mediaManager.getPlayIndex())
        XCTAssertEqual("v1", appManager.getCurrentVideo()?.id)
        XCTAssertEqual(.start, appManager.videoPlayerStatus.status)
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
        var expect: XCTestExpectation
        var timer: Timer

        // ビデオ再生中
        appManager.videoPlayerStatus = VideoPlayerStatus(status: .start)
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
        XCTAssertEqual(.start, appManager.videoPlayerStatus.status)

        // ビデオ停止中
        appManager.videoPlayerStatus = VideoPlayerStatus(status: .pause)
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
        XCTAssertEqual(.pause, appManager.videoPlayerStatus.status)
    }

    func test_closeAlbum() {
        appManager.closeAlbum()
        XCTAssertEqual(.close, appManager.videoPlayerStatus.status)
    }

    func test_startPlay() {
        appManager.startPlay()
        XCTAssertEqual(.start, appManager.videoPlayerStatus.status)

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
        // Album無しで実施した場合はcloseする
        appManager.nextPlay()
        XCTAssertEqual(.close, appManager.videoPlayerStatus.status)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album)

        // 0 => 1
        appManager.nextPlay()
        XCTAssertEqual(.start, appManager.videoPlayerStatus.status)

        // 1 => 2
        appManager.nextPlay()
        XCTAssertEqual(.start, appManager.videoPlayerStatus.status)

        // 2 => close
        appManager.nextPlay()
        XCTAssertEqual(.close, appManager.videoPlayerStatus.status)
    }
    
    func test_previousPlay() {
        // Album無しで実施した場合は何も起きない
        appManager.previousPlay()
        XCTAssertEqual(.none, appManager.videoPlayerStatus.status)

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
        appManager.previousPlay()
        XCTAssertEqual(.start, appManager.videoPlayerStatus.status)
        
        // 0 => 0 何も起きない
        appManager.previousPlay()
        XCTAssertEqual(.start, appManager.videoPlayerStatus.status)
    }
    
    func test_pausePlay() {
        // Album無しでもPauseできる
        appManager.pausePlay()
        XCTAssertEqual(false, appManager.hideNavigationBar)
        XCTAssertEqual(.pause, appManager.videoPlayerStatus.status)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album)

        // Pause
        appManager.pausePlay()
        XCTAssertEqual(false, appManager.hideNavigationBar)
        XCTAssertEqual(.pause, appManager.videoPlayerStatus.status)
    }

    func test_restartPlay() {
        // Album無しでRestartしても何も起きない
        appManager.restartPlay()
        XCTAssertEqual(.none, appManager.videoPlayerStatus.status)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album)
        
        // 再生中にrestartしても何も起きない
        appManager.restartPlay()
        XCTAssertEqual(.start, appManager.videoPlayerStatus.status)

        // Pause
        appManager.pausePlay()

        // Restart
        appManager.restartPlay()
        XCTAssertEqual(.restart, appManager.videoPlayerStatus.status)

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
        // Album無しでtoggleしても何も起きない
        appManager.togglePauseAndRestartPlay()
        XCTAssertEqual(.none, appManager.videoPlayerStatus.status)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album)

        // play => pause
        appManager.togglePauseAndRestartPlay()
        XCTAssertEqual(.pause, appManager.videoPlayerStatus.status)

        // pause => play
        appManager.togglePauseAndRestartPlay()
        XCTAssertEqual(.restart, appManager.videoPlayerStatus.status)
    }
    
}
