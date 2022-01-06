import Foundation
import SwiftUI
import Photos
import AVKit

class PlayerUIView: UIView {
    
    var delegate: playerDelegate?
    private let playerLayer0 = AVPlayerLayer()
    private let playerLayer1 = AVPlayerLayer()
    private var activePlayerLayer: Int = 0
    private let mediaManager = MediaManager()
    private let album: Album
    @ObservedObject private var appCoordinator: AppCoordinator

    init(appCoordinator: AppCoordinator, album: Album) {
        print("init : \(album.getTitle()) (\(album.videos.count))")
        self.album = album
        self.appCoordinator = appCoordinator
        super.init(frame: .zero)
        
        playerLayer0.opacity = 0
        self.layer.addSublayer(self.playerLayer0)
        playerLayer1.opacity = 0
        self.layer.addSublayer(self.playerLayer1)
        
        mediaManager.setAlbum(album: album)
        mediaManager.initializePlayList(sort: SettingsManager.sharedManager.settings.sortType)
        playVideo()
        
        // 再生開始して一定時間経過したらNavigationBarを非表示にする
        let _ = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block:
            {
            (time:Timer) in
                if appCoordinator.avPlayers.isPlaying() {
                    // 再生中なら非表示にする
                    self.appCoordinator.hideNavigationBar = true
                }
            }
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer0.frame = bounds
        playerLayer1.frame = bounds
    }
    
    func getActivePlayerLayer() -> AVPlayerLayer {
        if activePlayerLayer == 0 {
            return playerLayer0
        } else {
            return playerLayer1
        }
    }
    
    func getActivePlayer() -> AVPlayer {
        if activePlayerLayer == 0 {
            return appCoordinator.avPlayers.player0
        } else {
            return appCoordinator.avPlayers.player1
        }
    }
    
    func switchActivePlayerLayer() {
        activePlayerLayer = 1 - activePlayerLayer
    }

    func viewActivePlayerLayer() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.75)
        if activePlayerLayer == 0 {
            playerLayer0.opacity = 1
            playerLayer1.opacity = 0
        } else {
            playerLayer0.opacity = 0
            playerLayer1.opacity = 1
        }
        CATransaction.commit()
    }

    func playVideo() {
        if let video = mediaManager.getCurrentVideo() {
            let asset = video.asset
            guard (asset.mediaType == .video) else {
                print("Not a valid video media type")
                return
            }
            
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
            var rotationAngle: CGFloat = 0.0
            if SettingsManager.sharedManager.settings.orientationType == .portrait {
                if !isPortrait {
                    rotationAngle = .pi / 2
                }
            } else if SettingsManager.sharedManager.settings.orientationType == .landscape {
                if isPortrait {
                    rotationAngle = .pi / 2
                }
            }
            playerLayer0.setAffineTransform(CGAffineTransform(rotationAngle: rotationAngle))
            playerLayer1.setAffineTransform(CGAffineTransform(rotationAngle: rotationAngle))

            PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (asset, audioMix, args) in
                let avUrlAsset = asset as! AVURLAsset
                let playerItem: AVPlayerItem = AVPlayerItem(asset: avUrlAsset)

                DispatchQueue.main.async {
                    self.switchActivePlayerLayer()
                    let player = self.getActivePlayer()
                    player.replaceCurrentItem(with: playerItem)
                    NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
                    player.seek(to: CMTime(seconds: 0, preferredTimescale: 600))
                    player.play()
                    self.getActivePlayerLayer().player = player
                    self.viewActivePlayerLayer()
                }
            }
        } else {
            delegate?.finish()
        }

    }
    
    @objc func playerDidFinishPlaying() {
        guard let delegate = delegate else {
            return
        }
        if mediaManager.next() {
            playVideo()
        } else {
            delegate.finish()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
