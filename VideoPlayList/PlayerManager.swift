import Foundation
import AVKit

class PlayerManager: NSObject, ObservableObject {

    @Published var requestStartPlayer: Bool = false
    @Published var requestPausePlayer: Bool = false
    @Published var requestRestartPlayer: Bool = false
    @Published var requestClearPlayer: Bool = false

}
