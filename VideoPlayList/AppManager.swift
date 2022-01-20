import Foundation
import Photos

/// アプリ全体の制御を行う
class AppManager: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {

    @Published var showingPhotoLibraryAuthorizedAlert = false // 写真アクセスが許可されていない時に警告を表示
    @Published var navigationTitle = "" // タイトル表示の文言
    @Published var currentVideo: Video? = nil // 再生中のビデオ
    @Published var hideNavigationBar = false // ビデオ再生中のナビゲーションを非表示にする
    @Published var pauseVideoPlayer: Bool = false // ビデオ再生を一時停止する
    @Published var rotationAngle: CGFloat = 0 // 表示角度を変える

    var mediaUtility: MediaUtility = MediaUtility()
    let mediaManager = MediaManager()
    var albums: [Album] = []

    init(albums: [Album]) {
        super.init()
        navigationTitle = createNavigationTitle(albums: albums)
    }
    
    override convenience init() {
        self.init(albums: [])
    }
    
    //
    // MARK: Photo access
    //
    
    /// アルバム更新通知
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("AppManager.photoLibraryDidChange")
        loadAlbum()
    }

    //
    // MARK: App control
    //

    /// App開始
    func start() {
        print("AppManager.start")
        loadAlbum()
    }
    
    func setAlbums(albums: [Album]) {
        self.albums = albums
        currentVideo = nil
        pauseVideoPlayer = false
        navigationTitle = createNavigationTitle(albums: albums)
    }
    
    private func loadAlbum() {
        // 写真アクセス許可が得られているか確認
        print("AppManager.updateAlbum")
        mediaUtility.register(photoLibraryChangeObserver: self) { authorized in
            DispatchQueue.main.async {
                // ※ Publish変数のbackground threadでの更新は許可されていない為、main threadで処理する
                var albums: [Album] = []
                if authorized {
                    // Photoライブラリへのアクセスが許可されていたらアルバムを読み込む
                    albums = self.mediaUtility.load()
                } else {
                    // 許可されていない場合はアラート表示を有効にする
                    self.showingPhotoLibraryAuthorizedAlert = true
                }
                self.setAlbums(albums: albums)
            }
        }
    }
    
    private func createNavigationTitle(albums: [Album]) -> String {
        if albums.count > 0 {
            return "\(NSLocalizedString("video albums", comment: "video albums")) (\(albums.count))"
        }
        return "\(NSLocalizedString("no video albums", comment: "no video albums"))"
    }
    
    //
    // MARK: Player control
    //
    
    func openAlbum(album: Album, rotationAngle: CGFloat, sort: SettingsSortType) {
        print("AppManager.openAlbum : \(album.getTitle()) (\(album.videos.count))")
        mediaManager.setAlbum(album: album)
        mediaManager.initializePlayList(sort: sort)
        self.rotationAngle = rotationAngle
        startPlay()
    }
    
    func timerHideNavigationBar() {
        let _ = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: {
            (time:Timer) in
            if !self.pauseVideoPlayer {
                self.hideNavigationBar = true
            }
        })
    }
    
    func closeAlbum() {
        print("AppManager.closeAlbum")
        currentVideo = nil
    }
    
    func startPlay() {
        print("AppManager.startPlay")
        currentVideo = mediaManager.getCurrentVideo()
        timerHideNavigationBar()
    }
    
    func nextPlay() {
        print("AppManager.nextPlay : index=\(mediaManager.getPlayIndex() + 1)/\(mediaManager.getPlayList().count)")
        if mediaManager.next() {
            startPlay()
        } else {
            closeAlbum()
        }
    }
    
    func previousPlay() {
        print("AppManager.previousPlay : index=\(mediaManager.getPlayIndex() + 1)/\(mediaManager.getPlayList().count)")
        if mediaManager.previous() {
            startPlay()
        }
    }
    
    func pausePlay() {
        print("AppManager.pausePlay")
        hideNavigationBar = false
        pauseVideoPlayer = true
    }

    func restartPlay() {
        print("AppManager.restartPlay")
        if mediaManager.getAlbum() != nil && pauseVideoPlayer {
            pauseVideoPlayer = false
            timerHideNavigationBar()
        }
    }
    
    func togglePauseAndRestartPlay() {
        print("AppManager.togglePauseAndRestartPlay")
        if mediaManager.getAlbum() != nil {
            if pauseVideoPlayer {
                restartPlay()
            } else {
                pausePlay()
            }
        }
    }
}

