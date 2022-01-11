import XCTest

class MediaManagerTests: XCTestCase {

    let mediaManager = MediaManager()
    let album: Album = PreviewAlbum(id: "1", title: "test1", videos: [
        PreviewVideo(id: "1", year: 2021, month: 12, day: 20),
        PreviewVideo(id: "2", year: 2021, month: 12, day: 10),
        PreviewVideo(id: "3", year: 2021, month: 12, day: 1),
    ])

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// 再生対象のアルバムを設定
    func test_setAlbum() throws {
        var targetAlbum: Album?
        
        targetAlbum = mediaManager.getAlbum()
        XCTAssertNil(targetAlbum)
        XCTAssertEqual(-1, mediaManager.getPlayIndex())

        mediaManager.setAlbum(album: album)
        targetAlbum = mediaManager.getAlbum()
        XCTAssertEqual("test1", targetAlbum?.getTitle())
    }

    /// PlayListを初期化,PlayListを取得
    func test_initializePlayList() {
        var results: [Video]

        mediaManager.initializePlayList(sort: .date_asc)
        results = mediaManager.getPlayList()
        XCTAssertEqual(0, results.count)
        XCTAssertEqual(-1, mediaManager.getPlayIndex())

        mediaManager.setAlbum(album: album)
        
        mediaManager.initializePlayList(sort: .date_asc)
        XCTAssertEqual(0, mediaManager.getPlayIndex())
        results = mediaManager.getPlayList()
        XCTAssertEqual(3, results.count)
        XCTAssertEqual("3", results[0].id)
        XCTAssertEqual("2", results[1].id)
        XCTAssertEqual("1", results[2].id)
        mediaManager.initializePlayList(sort: .date_desc)
        XCTAssertEqual(0, mediaManager.getPlayIndex())
        results = mediaManager.getPlayList()
        XCTAssertEqual(3, results.count)
        XCTAssertEqual("1", results[0].id)
        XCTAssertEqual("2", results[1].id)
        XCTAssertEqual("3", results[2].id)
        mediaManager.initializePlayList(sort: .shuffle)
        XCTAssertEqual(0, mediaManager.getPlayIndex())
        results = mediaManager.getPlayList()
        XCTAssertEqual(3, results.count)
        // shuffleの結果を保証できないのでテストは除外
    }
    
    /// 再生対象のビデオを取得
    func test_getCurrentVideo() {
        var currentVideo: Video?

        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertNil(currentVideo)
        
        mediaManager.initializePlayList(sort: .date_asc)
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertNil(currentVideo)

        mediaManager.setAlbum(album: album)
        mediaManager.initializePlayList(sort: .date_asc)
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("3", currentVideo?.id)
    }

    /// 次のビデオに切り替え
    func test_next() {
        var currentVideo: Video?
        var result: Bool

        // アルバム未設定の時
        result = mediaManager.next()
        XCTAssertFalse(result)
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertNil(currentVideo)

        // アルバム設定
        mediaManager.setAlbum(album: album)
        mediaManager.initializePlayList(sort: .date_asc)

        // No.1 => 2
        result = mediaManager.next()
        XCTAssertTrue(result)
        XCTAssertEqual(1, mediaManager.getPlayIndex())
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("2", currentVideo?.id)

        // No.2 => 3(最後)
        result = mediaManager.next()
        XCTAssertTrue(result)
        XCTAssertEqual(2, mediaManager.getPlayIndex())
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("1", currentVideo?.id)

        // 最後から更に進めても何も起きない
        result = mediaManager.next()
        XCTAssertFalse(result)
        XCTAssertEqual(2, mediaManager.getPlayIndex())
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("1", currentVideo?.id)
    }
    
    /// 前のビデオに切り替え
    func test_previous() {
        var currentVideo: Video?
        var result: Bool

        // アルバム未設定の時
        result = mediaManager.previous()
        XCTAssertFalse(result)
        XCTAssertEqual(-1, mediaManager.getPlayIndex())
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertNil(currentVideo)

        // アルバム設定の時
        mediaManager.setAlbum(album: album)
        mediaManager.initializePlayList(sort: .date_asc)

        // 最初の状態で戻そうとしても何も起きない
        result = mediaManager.previous()
        XCTAssertFalse(result)
        XCTAssertEqual(0, mediaManager.getPlayIndex())
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("3", currentVideo?.id)

        // No.1 => 3
        _ = mediaManager.next()
        _ = mediaManager.next()
        // No.3 => 2
        result = mediaManager.previous()
        XCTAssertEqual(1, mediaManager.getPlayIndex())
        XCTAssertTrue(result)
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("2", currentVideo?.id)

        // No.2 => 1
        result = mediaManager.previous()
        XCTAssertTrue(result)
        XCTAssertEqual(0, mediaManager.getPlayIndex())
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("3", currentVideo?.id)
    }
    
    /// 前のビデオに切り替え可能か確認
    func test_enablePrevious() {
        // アルバム未設定の時
        XCTAssertFalse(mediaManager.enablePrevious())

        // アルバム設定直後
        mediaManager.setAlbum(album: album)
        mediaManager.initializePlayList(sort: .date_asc)
        XCTAssertFalse(mediaManager.enablePrevious())

        // No.1 => 2
        _ = mediaManager.next()
        XCTAssertTrue(mediaManager.enablePrevious())

        // No.2 => 1
        _ = mediaManager.previous()
        XCTAssertFalse(mediaManager.enablePrevious())
    }
    
}
