import Foundation
import SwiftUI
import Photos
import AVKit

class PlayerUIView: UIView {
    
    @ObservedObject private var appManager: AppManager
    private let player = AVPlayer()
    private let playerLayer = AVPlayerLayer()

    init(appManager: AppManager) {
        self.appManager = appManager
        super.init(frame: .zero)
        self.playerLayer.player = self.player
        self.layer.addSublayer(self.playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    func startPlayer() {
        if let video = appManager.getCurrentVideo() {
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
            var rotate = false
            if SettingsManager.sharedManager.settings.orientationType == .portrait {
                if !isPortrait {
                    rotate = true
                }
            } else if SettingsManager.sharedManager.settings.orientationType == .landscape {
                if isPortrait {
                    rotate = true
                }
            }
            if rotate {
                appManager.rotationAngle = .pi / 2
            } else {
                appManager.rotationAngle = 0
            }
            rotatePlayerLayer(angle: appManager.rotationAngle)

            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            PHCachingImageManager().requestPlayerItem(forVideo: asset, options: options) { (playerItem, info) in
                DispatchQueue.main.async {
                    self.player.replaceCurrentItem(with: playerItem)
                    NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
                    self.player.seek(to: CMTime(seconds: 0, preferredTimescale: 600))
                    self.player.play()
                }
            }
        } else {
            appManager.closeAlbum()
        }
    }
    
    func rotatePlayerLayer(angle: CGFloat) {
        playerLayer.setAffineTransform(CGAffineTransform(rotationAngle: angle))
    }
    
    func pausePlayer() {
        player.pause()
    }

    func restartPlayer() {
        player.play()
    }

    func clearPlayer() {
        player.replaceCurrentItem(with: nil)
    }

    @objc func playerDidFinishPlaying() {
        appManager.nextPlay()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
