import SwiftUI
import AVKit

struct VideoView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var appCoordinator: AppCoordinator
    var album: Album

    var body: some View {
        GeometryReader { bodyView in
            ZStack() {
                Color.black.edgesIgnoringSafeArea(.all)
                PlayerView(appCoordinator: appCoordinator, album: album)
                    .accessibility(identifier: "VideoView_PlayerView")

            }
            .onTapGesture {
                self.appCoordinator.hideNavigationBar.toggle()
            }
        }
        .navigationBarHidden(appCoordinator.hideNavigationBar)
        .navigationBarBackButtonHidden(appCoordinator.hideNavigationBar)
        .edgesIgnoringSafeArea(.all)
        .onDisappear {
            // Viewを閉じる時にPlayerを停止させる
            // (停止させないとスクリーンロックが無効なままになってしまう為)
            appCoordinator.pauseAVPlayer()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                // 再生中にバックグラウンド状態に
                appCoordinator.pauseAVPlayer()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        let previewAlbum = PreviewAlbum(id: "1", title: "album1", videos: [
                PreviewVideo(id: "1", year: 2021, month: 12, day: 20),
                PreviewVideo(id: "2", year: 2021, month: 12, day: 10),
                PreviewVideo(id: "3", year: 2021, month: 12, day: 1),
            ])
        VideoView(appCoordinator: AppCoordinator(), album: previewAlbum)
    }
}

struct PlayerView: UIViewRepresentable, playerDelegate {

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var appCoordinator: AppCoordinator
    var album: Album

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
    }

    func makeUIView(context: Context) -> UIView {
        appCoordinator.hideNavigationBar = false
        let view = PlayerUIView(appCoordinator: appCoordinator, album: album)
        view.delegate = self
        return view
    }

    func finish() {
        appCoordinator.pauseAVPlayer()
        presentationMode.wrappedValue.dismiss()
    }
    
}

protocol playerDelegate {
    func finish()
}
