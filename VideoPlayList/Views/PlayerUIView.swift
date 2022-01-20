import Foundation
import Photos
import AVKit

protocol PlayerDelegate {
    func playerDidFinish()
}

class PlayerUIView: UIView {
    
    private let player = AVPlayer()
    private let playerLayer = AVPlayerLayer()
    var delegate: PlayerDelegate?

    init() {
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
    
    func startPlayer(currentVideo: Video?, rotationAngle: CGFloat) {
        if let video = currentVideo {
            let asset = video.asset
            guard (asset.mediaType == .video) else {
                print("Not a valid video media type")
                delegate?.playerDidFinish()
                return
            }
            
            rotatePlayerLayer(angle: rotationAngle)

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
            delegate?.playerDidFinish()
        }
    }
    
    func rotatePlayerLayer(angle: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.setAffineTransform(CGAffineTransform(rotationAngle: angle))
        CATransaction.commit()
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
        delegate?.playerDidFinish()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
