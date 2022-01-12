import Foundation
import Photos

/// アプリ全体の制御を行う
class AppManager: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {

    @Published var model: Model
    @Published var navigationTitle = ""
    @Published var hideNavigationBar = false
    @Published var showingPhotoLibraryAuthorizedAlert = false
    @Published var requestCloseAlbum = Request()
    @Published var requestPlayStart = Request()
    @Published var requestPausePlay = Request()
    @Published var requestRestartPlay = Request()
    @Published var rotationAngle: CGFloat = 0


    let mediaUtility = MediaUtility()
    let mediaManager = MediaManager()
    var photoLibraryAuthorized = false
    var pausePlayFlag = false

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
    
    /// アプリ起動時に写真アクセス許可が得られているか確認
    private func checkAuthorizationStatus() {
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        print("AppManager.PHPhotoLibrary.authorizationStatus")
        printAuthorizationStatus(authStatus: authStatus)
        if isAuthorized(authStatus: authStatus) {
            photoLibraryAuthorized = true
        }
    }
    
    func isAuthorized(authStatus: PHAuthorizationStatus) -> Bool {
        if authStatus == .authorized {
            return true
        } else {
            return false
        }
    }
    
    private func printAuthorizationStatus(authStatus: PHAuthorizationStatus) {
        switch authStatus {
        case .notDetermined: // 未設定
            print("PHAuthorizationStatus.notDetermined")
        case .restricted: // ユーザがアクセス権限を持っていない
            print("PHAuthorizationStatus.restricted")
        case .denied: // アクセス拒否
            print("PHAuthorizationStatus.denied")
        case .authorized: // 全ての写真へのアクセスを許可
            print("PHAuthorizationStatus.authorized")
        case .limited: // 写真を選択
            print("PHAuthorizationStatus.limited")
        @unknown default:
            print("PHAuthorizationStatus.default")
        }
    }
    
    /// アルバム更新通知
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("AppManager.photoLibraryDidChange")
        updateModel()
    }

    //
    // MARK: App control
    //

    /// App開始
    func start() {
        print("AppManager.start")
        navigationTitle = createNavigationTitle(model: model)
        checkAuthorizationStatus()
        updateModel()
    }
    
    private func updateModel() {
        // 写真アクセス許可が得られているか確認
        if !photoLibraryAuthorized {
            print("AppManager.PHPhotoLibrary.requestAuthorization")
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [self] (authStatus) in
                printAuthorizationStatus(authStatus: authStatus)
                if isAuthorized(authStatus: authStatus) {
                    photoLibraryAuthorized = true
                    updateModel()
                } else {
                    // Publish変数のbackground threadでの更新は許可されていない為、main threadで処理する
                    DispatchQueue.main.async {
                        // 許可が得られていない場合はアラート表示を有効にする
                        showingPhotoLibraryAuthorizedAlert = true
                    }
                }
            }
            return
        }
        PHPhotoLibrary.shared().register(self)

        DispatchQueue.main.async {
            let albums = self.mediaUtility.load()
            self.model = Model(albums: albums)
            self.navigationTitle = self.createNavigationTitle(model: self.model)
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

    func timerHideNavigationBar() {
        let _ = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: {
            (time:Timer) in
            if !self.pausePlayFlag {
                self.hideNavigationBar = true
            }
        })
    }
    
    func closeAlbum() {
        print("AppManager.closeAlbum")
        requestCloseAlbum = Request()
    }
    
    func startPlay() {
        pausePlayFlag = false
        requestPlayStart = Request()
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
        pausePlayFlag = true
        requestPausePlay = Request()
    }

    func restartPlay() {
        print("AppManager.restartPlay")
        if mediaManager.getAlbum() != nil && pausePlayFlag {
            pausePlayFlag = false
            requestRestartPlay = Request()
            timerHideNavigationBar()
        }
    }
    
    func togglePauseAndRestartPlay() {
        print("AppManager.togglePauseAndRestartPlay")
        if mediaManager.getAlbum() != nil {
            if pausePlayFlag {
                restartPlay()
            } else {
                pausePlay()
            }
        }
    }
}

struct Request: Equatable {
    var requestedDate = Date()
}

