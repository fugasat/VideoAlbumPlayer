import Foundation

class MediaManager {
    
    private var album: Album?
    private var playList: [Video] = []
    private var playIndex: Int = -1
    
    func setAlbum(album: Album) {
        self.album = album
    }
    
    func getAlbum() -> Album? {
        return album
    }
    
    func initializePlayList(sort: SettingsSortType) {
        if album == nil {
            return
        }

        var result: [Video] = []
        switch (sort) {
        case .date_asc:
            result = album!.videos.sorted {
                return $0.getCreationDate() < $1.getCreationDate()
            }
        case .date_desc:
            result = album!.videos.sorted {
                return $0.getCreationDate() > $1.getCreationDate()
            }
        case .shuffle:
            result = album!.videos.shuffled()
        }
        playList = result
        playIndex = 0
    }
    
    func getPlayList() -> [Video] {
        return playList
    }
    
    func getCurrentVideo() -> Video? {
        if playIndex >= 0 && playIndex < playList.count {
            return playList[playIndex]
        } else {
            return nil
        }
    }
    
    func next() -> Bool {
        if playList.count == 0 {
            return false
        }
        playIndex += 1
        if playIndex >= playList.count {
            playIndex = playList.count - 1
            return false
        }
        return true
    }
    
    func previous() -> Bool {
        if playList.count == 0 {
            return false
        }
        playIndex -= 1
        if playIndex < 0 {
            playIndex = 0
            return false
        }
        return true
    }

}
