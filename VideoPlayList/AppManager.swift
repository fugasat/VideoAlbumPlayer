import Foundation
import Photos

class VideoPlayerStatus: Equatable {

    enum VideoPlayerStatusType : Int {
        case none = -1
        case start = 0
        case pause = 1
        case restart = 2
        case close = 3
    }

    let status: VideoPlayerStatusType

    init(status: VideoPlayerStatusType) {
        self.status = status
    }

    static func == (lhs: VideoPlayerStatus, rhs: VideoPlayerStatus) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

/// アプリ全体の制御を行う
class AppManager: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {

    @Published var model: Model
    @Published var navigationTitle = ""
    @Published var hideNavigationBar = false
    @Published var showingPhotoLibraryAuthorizedAlert = false
    @Published var videoPlayerStatus: VideoPlayerStatus = VideoPlayerStatus(status: .none)
    @Published var rotationAngle: CGFloat = 0

    let mediaUtility = MediaUtility()
    let mediaManager = MediaManager()

    override init() {
        model = Model()
        super.init()
    }
    
    convenience init(model: Model) {
        self.init()
        self.model = model
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
        navigationTitle = createNavigationTitle(model: model)
        loadAlbum()
    }
    
    private func loadAlbum() {
        // 写真アクセス許可が得られているか確認
        print("AppManager.updateAlbum")
        mediaUtility.register(photoLibraryChangeObserver: self) { authorized in
            DispatchQueue.main.async {
                // ※ Publish変数のbackground threadでの更新は許可されていない為、main threadで処理する
                if authorized {
                    // Photoライブラリへのアクセスが許可されていたらアルバムを読み込む
                    let albums = self.mediaUtility.load()
                    self.model = Model(albums: albums)
                    self.navigationTitle = self.createNavigationTitle(model: self.model)
                } else {
                    // 許可されていない場合はアラート表示を有効にする
                    self.showingPhotoLibraryAuthorizedAlert = true
                }
            }
        }
    }
    
    func createNavigationTitle(model: Model) -> String {
        if model.albums.count > 0 {
            return "\(NSLocalizedString("video albums", comment: "video albums")) (\(model.albums.count))"
        } else {
            return "\(NSLocalizedString("no video albums", comment: "no video albums"))"
        }
    }
    
    //
    // MARK: Player control
    //
    
    func openAlbum(album: Album) {
        print("AppManager.openAlbum : \(album.getTitle()) (\(album.videos.count))")
        mediaManager.setAlbum(album: album)
        mediaManager.initializePlayList(sort: SettingsManager.sharedManager.settings.sortType)
        rotationAngle = 0
        startPlay()
    }
    
    func getCurrentVideo() -> Video? {
        return mediaManager.getCurrentVideo()
    }

    func isPause() -> Bool {
        if self.videoPlayerStatus.status == .pause {
            return true
        } else {
            return false
        }
    }
    
    func timerHideNavigationBar() {
        let _ = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: {
            (time:Timer) in
            if !self.isPause() {
                self.hideNavigationBar = true
            }
        })
    }
    
    func closeAlbum() {
        print("AppManager.closeAlbum")
        videoPlayerStatus = VideoPlayerStatus(status: .close)
    }
    
    func startPlay() {
        print("AppManager.startPlay")
        videoPlayerStatus = VideoPlayerStatus(status: .start)
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
        videoPlayerStatus = VideoPlayerStatus(status: .pause)
    }

    func restartPlay() {
        print("AppManager.restartPlay")
        if mediaManager.getAlbum() != nil && isPause() {
            videoPlayerStatus = VideoPlayerStatus(status: .restart)
            timerHideNavigationBar()
        }
    }
    
    func togglePauseAndRestartPlay() {
        print("AppManager.togglePauseAndRestartPlay")
        if mediaManager.getAlbum() != nil {
            if isPause() {
                restartPlay()
            } else {
                pausePlay()
            }
        }
    }
}

