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

    func test_再生対象のアルバムを設定() throws {
        var targetAlbum: Album?
        
        targetAlbum = mediaManager.getAlbum()
        XCTAssertNil(targetAlbum)

        mediaManager.setAlbum(album: album)
        targetAlbum = mediaManager.getAlbum()
        XCTAssertEqual("test1", targetAlbum?.getTitle())
    }

    func test_PlayListを初期化_PlayListを取得() {
        var results: [Video]

        mediaManager.initializePlayList(sort: .date_asc)
        results = mediaManager.getPlayList()
        XCTAssertEqual(0, results.count)
        
        mediaManager.setAlbum(album: album)
        
        mediaManager.initializePlayList(sort: .date_asc)
        results = mediaManager.getPlayList()
        XCTAssertEqual(3, results.count)
        XCTAssertEqual("3", results[0].id)
        XCTAssertEqual("2", results[1].id)
        XCTAssertEqual("1", results[2].id)
        mediaManager.initializePlayList(sort: .date_desc)
        results = mediaManager.getPlayList()
        XCTAssertEqual(3, results.count)
        XCTAssertEqual("1", results[0].id)
        XCTAssertEqual("2", results[1].id)
        XCTAssertEqual("3", results[2].id)
        mediaManager.initializePlayList(sort: .shuffle)
        results = mediaManager.getPlayList()
        XCTAssertEqual(3, results.count)
        // shuffleの結果を保証できないのでテストは除外
    }
    
    func test_再生対象のビデオを取得() {
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

    func test_次のビデオに切り替え() {
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
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("2", currentVideo?.id)

        // No.2 => 3(最後)
        result = mediaManager.next()
        XCTAssertTrue(result)
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("1", currentVideo?.id)

        // 最後から更に進めても何も起きない
        result = mediaManager.next()
        XCTAssertFalse(result)
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("1", currentVideo?.id)
    }
    
    func test_前のビデオに切り替え() {
        var currentVideo: Video?
        var result: Bool

        // アルバム未設定の時
        result = mediaManager.previous()
        XCTAssertFalse(result)
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertNil(currentVideo)

        // アルバム設定の時
        mediaManager.setAlbum(album: album)
        mediaManager.initializePlayList(sort: .date_asc)

        // 最初の状態で戻そうとしても何も起きない
        result = mediaManager.previous()
        XCTAssertFalse(result)
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("3", currentVideo?.id)

        // No.1 => 3
        _ = mediaManager.next()
        _ = mediaManager.next()
        // No.3 => 2
        result = mediaManager.previous()
        XCTAssertTrue(result)
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("2", currentVideo?.id)

        // No.2 => 1
        result = mediaManager.previous()
        XCTAssertTrue(result)
        currentVideo = mediaManager.getCurrentVideo()
        XCTAssertEqual("3", currentVideo?.id)
    }
    
}
