import SwiftUI

struct PlayerView: UIViewRepresentable {

    public enum PlayerStatus : Int {
        case none = -1
        case start = 0
        case pause = 1
        case restart = 2
        case clear = 3
    }

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var appManager: AppManager
    @Binding var status: PlayerStatus
    var album: Album

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
        DispatchQueue.main.async {
            let playerUIView = uiView as! PlayerUIView?
            switch (status) {
                case .none:
                    break
                case .start:
                    playerUIView?.startPlayer()
                case .pause:
                    playerUIView?.pausePlayer()
                case .restart:
                    playerUIView?.restartPlayer()
                case .clear:
                    playerUIView?.clearPlayer()
            }
            status = .none
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
        PlayerView(appManager: AppManager(), status: .constant(.none), album: PreviewAlbum(id: "1", title: "album1", videos: []))
    }
}
