import Foundation
import Photos

class MediaUtility {
    
    /// 写真アクセス許可を得る
    func register(photoLibraryChangeObserver: PHPhotoLibraryChangeObserver, handler: @escaping (Bool) ->()) {
        // 写真アクセス許可が得られているか確認
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if isAuthorized(authStatus: authStatus) {
            print("PHPhotoLibrary.authorized")
            registerPhotoLibrary(photoLibraryChangeObserver: photoLibraryChangeObserver, handler: handler)
        } else {
            print("PHPhotoLibrary.requestAuthorization")
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [self] (requestedAuthStatus) in
                if isAuthorized(authStatus: requestedAuthStatus) {
                    registerPhotoLibrary(photoLibraryChangeObserver: photoLibraryChangeObserver, handler: handler)
                } else {
                    handler(false)
                }
            }
        }
        
        // 写真アクセスを許可
        func registerPhotoLibrary(photoLibraryChangeObserver: PHPhotoLibraryChangeObserver, handler: @escaping (Bool) ->()) {
            PHPhotoLibrary.shared().register(photoLibraryChangeObserver)
            print("PHPhotoLibrary.registered")
            handler(true)
        }
    }
        
    /// 許可されているか確認
    func isAuthorized(authStatus: PHAuthorizationStatus) -> Bool {
        printAuthorizationStatus(authStatus: authStatus)
        if authStatus == .authorized {
            return true
        }
        return false
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
    
    /// アルバムを取得
    func load() -> [Album] {
        var resultAlbums: [Album] = []
        // ユーザーが作成したアルバムのみ取得(.album .albumRegular)
        let resultsAssetCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        resultsAssetCollection.enumerateObjects { assetCollection, _, _ in
            // アルバム内のAssetを全て取得
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let resultsAsset = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            // Videoのみ取得
            var videos: [Video] = []
            resultsAsset.enumerateObjects { asset, _, _ in
                if asset.mediaType == .video {
                    let video = Video(id: asset.localIdentifier, asset: asset)
                    videos.append(video)
                }
            }
            if videos.count > 0 {
                let album = Album(id: assetCollection.localIdentifier, assetCollection: assetCollection, videos: videos)
                resultAlbums.append(album)
            }
        }
        print("load albums(\(resultAlbums.count))")
        return resultAlbums
    }
}
