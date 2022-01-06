import Foundation
import Photos

class MediaUtility: NSObject, PHPhotoLibraryChangeObserver {
    
    override init() {
        super.init()
    }

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

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("photoLibraryDidChange OK")
    }
    
}
