import Foundation

class Model: ObservableObject {

    @Published var albums: [Album] = []

    init() {
    }
    
    init(albums: [Album]) {
        self.albums = albums
    }
    
}
