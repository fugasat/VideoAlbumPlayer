import Photos

class Album: Identifiable {
    let id: String
    private var assetCollection: PHAssetCollection
    var videos: [Video]
    
    init(id: String, assetCollection: PHAssetCollection, videos: [Video]) {
        self.id = id
        self.assetCollection = assetCollection
        self.videos = videos
    }
    
    func getTitle() -> String {
        return assetCollection.localizedTitle ?? ""
    }
    
}

class PreviewAlbum: Album {
    var title: String
    
    init(id: String, title: String, videos: [Video]) {
        self.title = title
        super.init(id: id, assetCollection: PHAssetCollection(), videos: videos)
    }
    
    override func getTitle() -> String {
        return self.title
    }
}
