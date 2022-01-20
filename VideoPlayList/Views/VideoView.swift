import SwiftUI

struct VideoView: View {

    enum SwipeAction : Int {
        case none = -1
        case close = 0
        case next = 1
        case previous = 2
    }

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var appManager: AppManager
    @State var playerStatus0: PlayerView.PlayerStatus = .none
    @State var playerStatus1: PlayerView.PlayerStatus = .none
    @State var offset_x : CGFloat = 0
    @State var offset_y : CGFloat = 0
    @State var swipeAction: SwipeAction = .none
    @State var playerIndex: Int = -1
    @State var opacity0: CGFloat = 0
    @State var opacity1: CGFloat = 0
    var album: Album

    var body: some View {
        GeometryReader { bodyView in
            Color.black.edgesIgnoringSafeArea(.all)
            ZStack() {
                PlayerView(appManager: appManager, status: $playerStatus0)
                    .accessibility(identifier: "VideoView_PlayerView0")
                    .offset(x:offset_x, y:offset_y)
                    .opacity(opacity0)
                PlayerView(appManager: appManager, status: $playerStatus1)
                    .accessibility(identifier: "VideoView_PlayerView1")
                    .offset(x:offset_x, y:offset_y)
                    .opacity(opacity1)
            }
            .onTapGesture {
                appManager.togglePauseAndRestartPlay()
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged{ value in
                        offset_x = value.translation.width
                        offset_y = value.translation.height
                    }
                    .onEnded { value in
                        withAnimation(.easeOut(duration: 0.15)) {
                            startSwipeAnimation(value: value)
                        }
                    }
            )
            .onAnimationCompleted(for: offset_x) {
                endSwipeAnimation()
            }
            .onAnimationCompleted(for: offset_y) {
                endSwipeAnimation()
            }
        }
        .navigationBarHidden(appManager.hideNavigationBar)
        .navigationBarBackButtonHidden(appManager.hideNavigationBar)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            openAlbum(album: album, orientationType: SettingsManager.sharedManager.settings.orientationType, sort: SettingsManager.sharedManager.settings.sortType)
        }
        .onChange(of: appManager.currentVideo) { newValue in
            if (newValue != nil) {
                startPlay()
            } else {
                closeAlbum()
            }
        }
        .onChange(of: appManager.pauseVideoPlayer) { newValue in
            if newValue {
                pausePlay()
            } else {
                restartPlay()
            }
        }
    }
    
    private func startSwipeAnimation(value: DragGesture.Value) {
        let swipe_rate = 0.1
        let screen_width = UIScreen.main.bounds.width
        let screen_height = UIScreen.main.bounds.height
        var translation_x = value.predictedEndTranslation.width / screen_width
        var translation_y = value.predictedEndTranslation.height / screen_height
        if abs(translation_x) > abs(translation_y) {
            translation_y = 0
        } else {
            translation_x = 0
        }

        if translation_x < swipe_rate * -1 {
            // left
            offset_x = screen_width * -1
            if appManager.rotationAngle == 0 {
                swipeAction = .next
            } else {
                swipeAction = .close
            }
        } else if translation_x > swipe_rate {
            // right
            offset_x = screen_width
            if appManager.rotationAngle == 0 {
                swipeAction = .previous
            } else {
                swipeAction = .close
            }
        } else if translation_y < swipe_rate * -1 {
            // up
            offset_y = screen_height * -1
            swipeAction = .close
            if appManager.rotationAngle == 0 {
                swipeAction = .close
            } else {
                swipeAction = .next
            }
        } else if translation_y > swipe_rate {
            // down
            offset_y = screen_height
            if appManager.rotationAngle == 0 {
                swipeAction = .close
            } else {
                swipeAction = .previous
            }
        } else {
            offset_x = 0
            offset_y = 0
        }
        
        if swipeAction == .previous {
            if !appManager.mediaManager.enablePrevious() {
                offset_x = 0
                offset_y = 0
                swipeAction = .none
            }
        }
    }

    private func endSwipeAnimation() {
        if swipeAction == .close {
            forceFinishPlay()
        } else if swipeAction == .next {
            forceNextPlay()
        } else if swipeAction == .previous {
            forcePreviousPlay()
        }
        swipeAction = .none
    }

    private func forceFinishPlay() {
        opacity0 = 0
        opacity1 = 0
        appManager.closeAlbum()
    }
    
    private func forceNextPlay() {
        initializePlayView()
        appManager.nextPlay()
    }
    
    private func forcePreviousPlay() {
        initializePlayView()
        appManager.previousPlay()
    }
    
    private func initializePlayView() {
        opacity0 = 0
        opacity1 = 0
        offset_x = 0
        offset_y = 0
        pausePlay()
    }
    
    private func openAlbum(album: Album, orientationType: SettingsOrientationType, sort: SettingsSortType) {
        // 画面の向きを取得
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        let isPortrait: Bool
        if window?.windowScene?.interfaceOrientation.isPortrait ?? true {
            isPortrait = true
        } else {
            isPortrait = false
        }

        // 画面と再生方向の向きから回転角度を決める
        var rotate = false
        if orientationType == .portrait {
            if !isPortrait {
                rotate = true
            }
        } else if orientationType == .landscape {
            if isPortrait {
                rotate = true
            }
        }
        var rotationAngle: CGFloat = 0
        if rotate {
            rotationAngle = .pi / 2
        }
        
        appManager.openAlbum(album: album, rotationAngle: rotationAngle, sort: sort)
    }
    
    private func startPlay() {
        if playerIndex < 0 {
            playerIndex = 0
        } else {
            playerIndex = 1 - playerIndex
        }
        if playerIndex % 2 == 0 {
            playerStatus0 = .start
            playerStatus1 = .pause
        } else {
            playerStatus1 = .start
            playerStatus0 = .pause
        }
        withAnimation(.easeOut(duration: 0.5)) {
            if playerIndex % 2 == 0 {
                opacity0 = 1
                opacity1 = 0
            } else {
                opacity0 = 0
                opacity1 = 1
            }
        }
    }

    private func pausePlay() {
        playerStatus0 = .pause
        playerStatus1 = .pause
    }
    
    private func restartPlay() {
        if playerIndex >= 0 {
            if playerIndex % 2 == 0 {
                playerStatus0 = .restart
            } else {
                playerStatus1 = .restart
            }
        }
    }
    
    private func closeAlbum() {
        pausePlay()
        presentationMode.wrappedValue.dismiss()
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        let previewAlbum = PreviewAlbum(id: "1", title: "album1", videos: [
                PreviewVideo(id: "1", year: 2021, month: 12, day: 20),
                PreviewVideo(id: "2", year: 2021, month: 12, day: 10),
                PreviewVideo(id: "3", year: 2021, month: 12, day: 1),
            ])
        VideoView(appManager: AppManager(), album: previewAlbum)
    }
}


/// An animatable modifier that is used for observing animations for a given animatable value.
struct AnimationCompletionObserverModifier<Value>: AnimatableModifier where Value: VectorArithmetic {

    /// While animating, SwiftUI changes the old input value to the new target value using this property. This value is set to the old value until the animation completes.
    var animatableData: Value {
        didSet {
            notifyCompletionIfFinished()
        }
    }

    /// The target value for which we're observing. This value is directly set once the animation starts. During animation, `animatableData` will hold the oldValue and is only updated to the target value once the animation completes.
    private var targetValue: Value

    /// The completion callback which is called once the animation completes.
    private var completion: () -> Void

    init(observedValue: Value, completion: @escaping () -> Void) {
        self.completion = completion
        self.animatableData = observedValue
        targetValue = observedValue
    }

    /// Verifies whether the current animation is finished and calls the completion callback if true.
    private func notifyCompletionIfFinished() {
        guard animatableData == targetValue else { return }

        /// Dispatching is needed to take the next runloop for the completion callback.
        /// This prevents errors like "Modifying state during view update, this will cause undefined behavior."
        DispatchQueue.main.async {
            self.completion()
        }
    }

    func body(content: Content) -> some View {
        /// We're not really modifying the view so we can directly return the original input value.
        return content
    }
}

extension View {

    /// Calls the completion handler whenever an animation on the given value completes.
    /// - Parameters:
    ///   - value: The value to observe for animations.
    ///   - completion: The completion callback to call once the animation completes.
    /// - Returns: A modified `View` instance with the observer attached.
    func onAnimationCompleted<Value: VectorArithmetic>(for value: Value, completion: @escaping () -> Void) -> ModifiedContent<Self, AnimationCompletionObserverModifier<Value>> {
        return modifier(AnimationCompletionObserverModifier(observedValue: value, completion: completion))
    }
}
