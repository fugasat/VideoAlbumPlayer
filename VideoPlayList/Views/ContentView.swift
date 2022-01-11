import SwiftUI
import AVKit
import Photos

struct ContentView: View {

    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var appManager = AppManager()
    @State private var showingSettingsModal = false

    var body: some View {
        NavigationView {
            List {
                ForEach(appManager.model.albums.indices, id: \.self) { index in
                    let album = appManager.model.albums[index]
                    NavigationLink(destination: VideoView(appManager: appManager, playerManager0: PlayerManager(), playerManager1: PlayerManager(), album: album)) {
                        HStack {
                            let baseIdentifier = "ContentView_List_\(index)_Text"
                            Text(album.getTitle())
                                .accessibility(identifier: "\(baseIdentifier)_title")
                            Spacer()
                            Text(String(album.videos.count)).foregroundColor(Color.secondary)
                                .accessibility(identifier: "\(baseIdentifier)_count")
                        }
                    }
                }
            }
            .accessibility(identifier: "ContentView_List")
            .navigationBarTitle(appManager.navigationTitle, displayMode: .inline)
            .navigationBarItems(trailing: Button(
                action: {
                    self.showingSettingsModal.toggle()
                }) {
                    Image(systemName: "gearshape.fill")
                }
            )
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    appManager.start()
                } else if phase == .background {
                    // 再生中にバックグラウンド状態に遷移した場合はViewを閉じる
                    appManager.closeAlbum()
                }
            }
            .sheet(isPresented: $showingSettingsModal) {
                SettingsView(showingSettingsModal: $showingSettingsModal)
            }
            .alert("access to photos", isPresented: $appManager.showingPhotoLibraryAuthorizedAlert){
                Button("cancel") {
                    
                }
                Button("settings"){
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString ) else {
                        return
                    }
                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                }
            } message: {
                Text("alert message")
            }
        }
        .accessibility(identifier: "ContentView_NavigationView")
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let previewAlbums: [Album] = [
            PreviewAlbum(id: "1", title: "album1", videos: [
                PreviewVideo(id: "1", year: 2021, month: 12, day: 20),
                PreviewVideo(id: "2", year: 2021, month: 12, day: 10),
                PreviewVideo(id: "3", year: 2021, month: 12, day: 1),
            ]),
            PreviewAlbum(id: "2", title: "album2", videos: [
                PreviewVideo(id: "1", year: 2020, month: 12, day: 1),
                PreviewVideo(id: "2", year: 2020, month: 8, day: 2),
            ]),
            PreviewAlbum(id: "3", title: "album3", videos: [
            ]),
            PreviewAlbum(id: "4", title: "", videos: [
            ]),
        ]
        let previewModel = Model(albums: previewAlbums)
        let appManager = AppManager(model: previewModel)
        ContentView(appManager: appManager)
    }
}

