import Foundation
import Photos

/// アプリ全体の制御を行う
class AppCoordinator: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {

    @Published var model: Model
    @Published var navigationTitle = ""
    @Published var hideNavigationBar = false
    @Published var showingPhotoLibraryAuthorizedAlert = false

    let mediaUtility = MediaUtility()
    let avPlayers = AVPlayers()
    var photoLibraryAuthorized = false

    override init() {
        model = Model()
        super.init()
        self.navigationTitle = self.createNavigationTitle(model: self.model)

        // アプリ起動時に写真アクセス許可が得られているか確認
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        print("AppCoordinator.PHPhotoLibrary.authorizationStatus")
        self.printAuthorizationStatus(authStatus: authStatus)
        if isAuthorized(authStatus: authStatus) {
            photoLibraryAuthorized = true
        }
    }
    
    convenience init(model: Model) {
        self.init()
        self.model = model
    }
    
    private func isAuthorized(authStatus: PHAuthorizationStatus) -> Bool {
        if authStatus != .notDetermined && authStatus != .denied  && authStatus != .limited {
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
        print("AppCoordinator.photoLibraryDidChange")
        updateModel()
    }

    /// Top View表示開始
    func startTopView() {
        print("AppCoordinator.startTopView")
        pauseAVPlayer()
        updateModel()
    }
    
    /// 再生中のAVPlayerを全て停止
    func pauseAVPlayer() {
        print("AppCoordinator.pauseAVPlayer")
        hideNavigationBar = false
        avPlayers.pause()
    }
    
    private func updateModel() {
        // 写真アクセス許可が得られているか確認
        if !photoLibraryAuthorized {
            print("AppCoordinator.PHPhotoLibrary.requestAuthorization")
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
    
    private func createNavigationTitle(model: Model) -> String {
        if model.albums.count > 0 {
            return "\(NSLocalizedString("video albums", comment: "video albums")) (\(model.albums.count))"
        } else {
            return "\(NSLocalizedString("no video albums", comment: "no video albums"))"
        }
    }
}

struct AVPlayers {
    var player0: AVPlayer = AVPlayer()
    var player1: AVPlayer = AVPlayer()
    
    func pause() {
        player0.pause()
        player1.pause()
    }
    
    func isPlaying() -> Bool {
        if (player0.rate != 0 && player0.error == nil) || (player1.rate != 0 && player1.error == nil) {
            return true
        } else {
            return false
        }
    }
}

