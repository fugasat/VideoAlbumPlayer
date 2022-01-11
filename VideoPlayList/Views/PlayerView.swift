import SwiftUI

struct PlayerView: UIViewRepresentable {

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var appManager: AppManager
    @ObservedObject var playerManager: PlayerManager
    @Binding var rotationAngle: CGFloat

    var album: Album

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
        DispatchQueue.main.async {
            let playerUIView = uiView as! PlayerUIView?
            if playerManager.requestStartPlayer {
                playerManager.requestStartPlayer = false
                playerUIView?.startPlayer()
            }
            if playerManager.requestPausePlayer {
                playerManager.requestPausePlayer = false
                playerUIView?.pausePlayer()
            }
            if playerManager.requestRestartPlayer {
                playerManager.requestRestartPlayer = false
                playerUIView?.restartPlayer()
            }
            if playerManager.requestClearPlayer {
                playerManager.requestClearPlayer = false
                playerUIView?.clearPlayer()
            }
            playerUIView?.rotatePlayerLayer(angle: appManager.rotationAngle)
        }
    }

    func makeUIView(context: Context) -> UIView {
        appManager.hideNavigationBar = false
        let view = PlayerUIView(appManager: appManager)
        return view
    }

}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView(appManager: AppManager(), playerManager: PlayerManager(), rotationAngle: .constant(0), album: PreviewAlbum(id: "1", title: "album1", videos: []))
    }
}
