import Photos

class Video: Identifiable, Equatable {
    let id: String
    var asset: PHAsset

    init(id: String, asset: PHAsset) {
        self.id = id
        self.asset = asset
    }

    func getCreationDate() -> Date! {
        return asset.creationDate
    }
    
    static func == (lhs: Video, rhs: Video) -> Bool {
        return lhs.id == rhs.id
    }

}

class PreviewVideo: Video {
    let calendar = Calendar(identifier: .gregorian)
    let creationDate: Date
        
    init(id: String, year: Int, month: Int, day: Int) {
        self.creationDate = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 0, minute: 0, second: 0))!
        super.init(id: id, asset: PHAsset())
    }

    override func getCreationDate() -> Date? {
        return self.creationDate
    }
}


