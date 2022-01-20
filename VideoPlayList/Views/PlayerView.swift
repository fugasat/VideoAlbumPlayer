import SwiftUI

struct PlayerView: UIViewRepresentable {

    public enum PlayerStatus : Int {
        case none = -1
        case start = 0
        case pause = 1
        case restart = 2
    }

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var appManager: AppManager
    @Binding var status: PlayerStatus

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
        if let playerUIView = uiView as! PlayerUIView? {
            DispatchQueue.main.async {
                switch (status) {
                case .start:
                    playerUIView.startPlayer(currentVideo: appManager.currentVideo, rotationAngle: appManager.rotationAngle)
                case .pause:
                    playerUIView.pausePlayer()
                case .restart:
                    playerUIView.restartPlayer()
                case .none:
                    break
                }
                status = .none
            }
        }
    }

    func makeUIView(context: Context) -> UIView {
        appManager.hideNavigationBar = false
        let view = PlayerUIView()
        view.delegate = context.coordinator
        return view
    }
    
    static func dismantleUIView(_ uiView: Self.UIViewType, coordinator: Self.Coordinator) {
        if let playerUIView = uiView as! PlayerUIView? {
            playerUIView.clearPlayer()
        }
    }
    
    func makeCoordinator() -> PlayerView.Coordinator {
        return Coordinator(appManager: appManager)
    }
    
}
extension PlayerView {
    
    // UIKit側で発生したイベントをViewで受け取る
    class Coordinator: NSObject, PlayerDelegate {
        
        @ObservedObject var appManager: AppManager

        init(appManager: AppManager) {
            self.appManager = appManager
        }
        
        func playerDidFinish() {
            appManager.nextPlay()
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView(appManager: AppManager(), status: .constant(.none))
    }
}
