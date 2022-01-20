import XCTest
import Photos

class AppManagerTest: XCTestCase {

    class MediaUtilityRegisterSuccess: MediaUtility {
        override func register(photoLibraryChangeObserver: PHPhotoLibraryChangeObserver, handler: @escaping (Bool) -> ()) {
            handler(true)
        }
        
        override func load() -> [Album] {
            let albums = [
                PreviewAlbum(id: "a1", title: "title1", videos: [
                    PreviewVideo(id: "v13", year: 2021, month: 1, day: 3),
                    PreviewVideo(id: "v12", year: 2021, month: 1, day: 2),
                    PreviewVideo(id: "v11", year: 2021, month: 1, day: 1),
                ]),
                PreviewAlbum(id: "a2", title: "title2", videos: [
                    PreviewVideo(id: "v22", year: 2022, month: 1, day: 2),
                    PreviewVideo(id: "v21", year: 2022, month: 1, day: 1),
                ]),
            ]
            return albums
        }
    }
    
    class MediaUtilityRegisterFail: MediaUtility {
        override func register(photoLibraryChangeObserver: PHPhotoLibraryChangeObserver, handler: @escaping (Bool) -> ()) {
            handler(false)
        }
        
        override func load() -> [Album] {
            return []
        }
    }
    
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

    func test_photoLibraryDidChange() throws {
        var expect: XCTestExpectation
        var timer: Timer

        appManager.mediaUtility = MediaUtilityRegisterSuccess() // 写真アクセス有効
        appManager.photoLibraryDidChange(PHChange())
        
        expect = expectation(description: "async test")
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            if self.appManager.albums.count > 0 {
                expect.fulfill() // Album取得が完了するまで待機
            }
        }
        wait(for: [expect], timeout: 3)
        timer.invalidate()

        XCTAssertEqual(2, appManager.albums.count)
        XCTAssertEqual("a1", appManager.albums[0].id)
        XCTAssertEqual("a2", appManager.albums[1].id)
        XCTAssertTrue(appManager.navigationTitle == "ビデオアルバム (2)" || appManager.navigationTitle == "Video Albums (2)")
        XCTAssertNil(appManager.currentVideo)
        XCTAssertFalse(appManager.pauseVideoPlayer)
    }

    //
    // MARK: App control
    //

    func test_start_success() throws {
        var expect: XCTestExpectation
        var timer: Timer

        appManager.mediaUtility = MediaUtilityRegisterSuccess() // 写真アクセス有効
        appManager.start()

        expect = expectation(description: "async test")
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            if self.appManager.albums.count > 0 {
                expect.fulfill() // Album取得が完了するまで待機
            }
        }
        wait(for: [expect], timeout: 3)
        timer.invalidate()

        XCTAssertEqual(2, appManager.albums.count)
        XCTAssertEqual("a1", appManager.albums[0].id)
        XCTAssertEqual("a2", appManager.albums[1].id)
        XCTAssertTrue(appManager.navigationTitle == "ビデオアルバム (2)" || appManager.navigationTitle == "Video Albums (2)")
        XCTAssertNil(appManager.currentVideo)
        XCTAssertFalse(appManager.pauseVideoPlayer)
    }
    
    func test_start_fail() throws {
        var expect: XCTestExpectation
        var timer: Timer

        appManager.mediaUtility = MediaUtilityRegisterFail() // 写真アクセス無効
        appManager.start()

        expect = expectation(description: "async test")
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            if self.appManager.showingPhotoLibraryAuthorizedAlert {
                expect.fulfill() // アラート表示が有効になるまで待機
            }
        }
        wait(for: [expect], timeout: 3)
        timer.invalidate()

        XCTAssertEqual(0, appManager.albums.count)
        XCTAssertTrue(appManager.navigationTitle == "ビデオアルバム無し" || appManager.navigationTitle == "No Video Albums")
        XCTAssertNil(appManager.currentVideo)
        XCTAssertFalse(appManager.pauseVideoPlayer)
    }
    
    func test_start_success_to_fail() throws {
        var expect: XCTestExpectation
        var timer: Timer

        // 初回は有効
        appManager.mediaUtility = MediaUtilityRegisterSuccess() // 写真アクセス有効
        appManager.start()

        expect = expectation(description: "async test")
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            if self.appManager.albums.count > 0 {
                expect.fulfill() // Album取得が完了するまで待機
            }
        }
        wait(for: [expect], timeout: 3)
        timer.invalidate()

        XCTAssertEqual(2, appManager.albums.count)
        XCTAssertEqual("a1", appManager.albums[0].id)
        XCTAssertEqual("a2", appManager.albums[1].id)
        XCTAssertTrue(appManager.navigationTitle == "ビデオアルバム (2)" || appManager.navigationTitle == "Video Albums (2)")
        XCTAssertNil(appManager.currentVideo)
        XCTAssertFalse(appManager.pauseVideoPlayer)
        
        // ２回目は無効
        appManager.mediaUtility = MediaUtilityRegisterFail() // 写真アクセス無効
        appManager.start()

        expect = expectation(description: "async test")
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            if self.appManager.showingPhotoLibraryAuthorizedAlert {
                expect.fulfill() // アラート表示が有効になるまで待機
            }
        }
        wait(for: [expect], timeout: 3)
        timer.invalidate()

        XCTAssertEqual(0, appManager.albums.count)
        XCTAssertTrue(appManager.navigationTitle == "ビデオアルバム無し" || appManager.navigationTitle == "No Video Albums")
        XCTAssertNil(appManager.currentVideo)
        XCTAssertFalse(appManager.pauseVideoPlayer)
    }

    func test_setAlbums() throws {
        // Album未設定
        XCTAssertNil(appManager.currentVideo)
        XCTAssertFalse(appManager.pauseVideoPlayer)
        XCTAssertTrue(appManager.navigationTitle == "ビデオアルバム無し" || appManager.navigationTitle == "No Video Albums")
        
        // Albumを設定
        let albums = [
            PreviewAlbum(id: "a1", title: "title1", videos: [
                PreviewVideo(id: "v13", year: 2021, month: 1, day: 3),
                PreviewVideo(id: "v12", year: 2021, month: 1, day: 2),
                PreviewVideo(id: "v11", year: 2021, month: 1, day: 1),
            ]),
            PreviewAlbum(id: "a2", title: "title2", videos: [
                PreviewVideo(id: "v23", year: 2022, month: 1, day: 3),
                PreviewVideo(id: "v22", year: 2022, month: 1, day: 2),
                PreviewVideo(id: "v21", year: 2022, month: 1, day: 1),
            ]),
        ]
        appManager.setAlbums(albums: albums)
        XCTAssertTrue(appManager.navigationTitle == "ビデオアルバム (2)" || appManager.navigationTitle == "Video Albums (2)")
        XCTAssertNil(appManager.currentVideo)
        XCTAssertFalse(appManager.pauseVideoPlayer)
    }
    
    //
    // MARK: Player control
    //
    
    func test_openAlbum() throws {
        // Album未設定
        XCTAssertNil(appManager.currentVideo)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album, rotationAngle: 0, sort: .date_asc)
        XCTAssertEqual(0, appManager.rotationAngle)
        XCTAssertEqual("a1", appManager.mediaManager.getAlbum()?.id)
        XCTAssertEqual(0, appManager.mediaManager.getPlayIndex())
        XCTAssertEqual("v1", appManager.currentVideo?.id)
        
        appManager.openAlbum(album: album, rotationAngle: 90, sort: .date_desc)
        XCTAssertEqual(90, appManager.rotationAngle)
        XCTAssertEqual("a1", appManager.mediaManager.getAlbum()?.id)
        XCTAssertEqual(0, appManager.mediaManager.getPlayIndex())
        XCTAssertEqual("v3", appManager.currentVideo?.id)

    }
    
    func test_timerHideNavigationBar() throws {
        var expect: XCTestExpectation
        var timer: Timer

        // ビデオ再生中
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

        // ビデオ停止中
        appManager.pauseVideoPlayer = true
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
        XCTAssertEqual(true, appManager.pauseVideoPlayer)
    }

    func test_closeAlbum() {
        // Album未設定
        appManager.closeAlbum()
        XCTAssertNil(appManager.currentVideo)
        
        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album, rotationAngle: 0, sort: .date_asc)
        appManager.closeAlbum()
        XCTAssertNil(appManager.currentVideo)
    }

    func test_startPlay() {
        appManager.startPlay()

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
        XCTAssertNil(appManager.currentVideo)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album, rotationAngle: 0, sort: .date_asc)

        // 0 => 1
        appManager.nextPlay()
        XCTAssertEqual("v2", appManager.currentVideo?.id)

        // 1 => 2
        appManager.nextPlay()
        XCTAssertEqual("v3", appManager.currentVideo?.id)

        // 2 => close
        appManager.nextPlay()
        XCTAssertNil(appManager.currentVideo)
    }
    
    func test_previousPlay() {
        // Album無しで実施した場合は何も起きない
        appManager.previousPlay()
        XCTAssertNil(appManager.currentVideo)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album, rotationAngle: 0, sort: .date_asc)

        // 0 => 1
        appManager.nextPlay()

        // 1 => 0
        appManager.previousPlay()
        XCTAssertEqual("v1", appManager.currentVideo?.id)

        // 0 => 0 何も起きない
        appManager.previousPlay()
        XCTAssertEqual("v1", appManager.currentVideo?.id)
    }
    
    func test_pausePlay() {
        // Album無しでもPauseできる
        appManager.pausePlay()
        XCTAssertEqual(false, appManager.hideNavigationBar)
        XCTAssertEqual(true, appManager.pauseVideoPlayer)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album, rotationAngle: 0, sort: .date_asc)

        // Pause
        appManager.pausePlay()
        XCTAssertEqual(false, appManager.hideNavigationBar)
        XCTAssertEqual(true, appManager.pauseVideoPlayer)
    }

    func test_restartPlay() {
        // Album無しでRestartしても何も起きない
        appManager.restartPlay()
        XCTAssertNil(appManager.currentVideo)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album, rotationAngle: 0, sort: .date_asc)
        
        // 再生中にrestartしても何も起きない
        appManager.restartPlay()
        XCTAssertEqual("v1", appManager.currentVideo?.id)

        // Pause
        appManager.pausePlay()
        XCTAssertEqual(true, appManager.pauseVideoPlayer)

        // Restart
        appManager.restartPlay()
        XCTAssertEqual(false, appManager.pauseVideoPlayer)

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
        XCTAssertEqual(false, appManager.pauseVideoPlayer)

        // Albumを設定
        let album = PreviewAlbum(id: "a1", title: "title1", videos: [
            PreviewVideo(id: "v3", year: 2021, month: 1, day: 3),
            PreviewVideo(id: "v2", year: 2021, month: 1, day: 2),
            PreviewVideo(id: "v1", year: 2021, month: 1, day: 1),
        ])
        appManager.openAlbum(album: album, rotationAngle: 0, sort: .date_asc)

        // play => pause
        appManager.togglePauseAndRestartPlay()
        XCTAssertEqual(true, appManager.pauseVideoPlayer)

        // pause => play
        appManager.togglePauseAndRestartPlay()
        XCTAssertEqual(false, appManager.pauseVideoPlayer)
    }
    
}
