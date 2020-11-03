//
//  QKAVPlayerManager.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/6.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit
import AVFoundation

let kStatus                 = "status"
let kLoadedTimeRanges       = "loadedTimeRanges"
let kPlaybackBufferEmpty    = "playbackBufferEmpty"
let kPlaybackLikelyToKeepUp = "playbackLikelyToKeepUp"
let kPresentationSize       = "presentationSize"

class QKAVPlayerManager: NSObject, QKPlayerMediaPlayback {
    
    
    // 链接
    private(set) var asset: AVURLAsset?
    // 控制操作对象
    private(set) var playerItem: AVPlayerItem?
    // 控制器
    private(set) var player: AVPlayer?
    // layer视图
    private var playerLayer: AVPlayerLayer?
    // 刷新时间，默认0.1
    public var timerRefreshInterVal: TimeInterval = 0.1
    // 视频请求头
    public var videoRequestHeader: Dictionary<String, Any>?
    // 播放时间的监听
    private var timerObserver: Any?
    // 视频时间播放结束监听
    private var itemEndObserver: Any?
    // 监听数据
    private var playerItemObserver: QKObserverControl?
    // 是否正在缓存 默认false
    private var isBuffering: Bool = false
    // 是否准备播放 默认false
    private var isReadyToPlay = false
    // 默认播放速度
    let rateSpeed: Float = 1.0
    
    // ------------ QKPlayerMediaPlayback ------------
    
    var view: QKPlayerView? = QKPlayerPresentView()
    
    var volume: Float? {
        willSet (_volume) {
            self.volume = min(max(0, _volume ?? 0), 1)
            guard let isMuted = self.volume else { return }
            self.player?.volume = isMuted
        }
    }
    
    var isMuted: Bool? {
        willSet {
            guard let _isMuted = newValue else { return }
            self.player?.isMuted = _isMuted
        }
    }
    
    var rate: Float? {
        willSet {
            if self.player != nil && fabsf(player?.rate ?? 0) > 0.0001 {
                self.player?.rate = newValue ?? rateSpeed
            }
        }
    }
    
    var currentTime: TimeInterval? {
        get {
            let sec = CMTimeGetSeconds(self.playerItem?.currentTime() ?? .zero)
            if sec.isNaN || sec < 0 {
                return 0
            }
            return sec
        }
        set {}
    }
    
    var totalTime: TimeInterval? {
        get {
            let sec = CMTimeGetSeconds(self.player?.currentItem?.duration ?? .zero)
            if sec.isNaN {
                return 0
            }
            return sec
        }
        set { }
    }
    
    var bufferTime: TimeInterval?
    
    var seekTime: TimeInterval?
    
    var isPlaying: Bool?
    
    var isPreparedToPlay: Bool?
    
    var shouldAutoPlay: Bool?
    
    var assetURL: URL? {
        didSet {
            if self.player != nil { self.stop()} // 如果有播放的话，那么先暂停
            self.prepareToPlay()
        }
    }
    
    var presentationSize: CGSize?
    
    var scalingModel: QKPlayerScalingMode? {
        willSet {
            let presentationView = self.view as? QKPlayerPresentView
            switch newValue {
            case .none:
                presentationView?.videoGravity = .resizeAspect
            case .aspectFit:
                presentationView?.videoGravity = .resizeAspect
            case .aspectFill:
                presentationView?.videoGravity = .resizeAspectFill
            case .fill:
                presentationView?.videoGravity = .resize
            default:
                break
            }
        }
        
    }
    
    var playState: QKPlayerPlaybackState? {
        willSet {
            if let playerPlayStateChanged = self.playerPlayStateChanged, let _playState = newValue {
                playerPlayStateChanged(self, _playState)
            }
        }
    }
    
    var loadState: QKPlayerLoadState? {
        willSet {
            if let playerLoadStateChanged = self.playerLoadStateChanged, let _loadState = newValue {
                playerLoadStateChanged(self, _loadState)
            }
        }
    }
    
    var playerPrepareToPlay: ((QKPlayerMediaPlayback, URL) -> Void)?
    
    var playerReadyToPlay: ((QKPlayerMediaPlayback, URL) -> Void)?
    
    var playerPlayTimeChange: ((QKPlayerMediaPlayback, TimeInterval, TimeInterval) -> Void)?
    
    var playerBufferTimeChanged: ((QKPlayerMediaPlayback, TimeInterval) -> Void)?
    
    var playerPlayStateChanged: ((QKPlayerMediaPlayback, QKPlayerPlaybackState) -> Void)?
    
    var playerLoadStateChanged: ((QKPlayerMediaPlayback, QKPlayerLoadState) -> Void)?
    
    var playerPlayFaild: ((QKPlayerMediaPlayback, Any) -> Void)?
    
    var playerDidToEnd: ((QKPlayerMediaPlayback) -> Void)?
    
    var presentationSizeChanged: ((QKPlayerMediaPlayback, CGSize) -> Void)?
    
    func prepareToPlay() {
        guard let assetURL = self.assetURL else { return }
        self.isPreparedToPlay = true
        self.initializePlayer()
        if self.shouldAutoPlay == true {
            self.play()
        }
        self.loadState = .prepare
        if let playerPrepareToPlay = self.playerPrepareToPlay {
            playerPrepareToPlay(self, assetURL)
        }
    }
    
    func reloadPlayer() {
        self.seekTime = self.currentTime // 重新载入后滑至当前时间
        self.prepareToPlay()
        
    }
    
    func play() {
        if isPreparedToPlay == false {
            self.prepareToPlay()
        } else {
            self.player?.play()
//            self.player?.rate = self.rate ?? rateSpeed
            self.isPlaying = true
            self.playState = .playing
        }
    }
    
    func pause() {
        self.player?.pause()
        self.isPlaying = false
        self.playState = .paused
        self.playerItem?.cancelPendingSeeks() // 取消任何还没成功的请求，如果存在，则调用相应的完成处理程序。
        asset?.cancelLoading() // 取消加载
    }
    
    func stop() {
        playerItemObserver?.qkRemoveAllObservers()
        self.loadState = .unkown
        self.playState = .playStopped
        if self.player?.rate != 0 { self.player?.pause() } // 表示所需的播放速度，0.0表示 "暂停"，1.0表示希望以当前项目的自然速度播放。不等0时，暂停
        self.player?.replaceCurrentItem(with: nil)
        playerItemObserver = nil
        if let itemEndObserver = itemEndObserver {
            NotificationCenter.default.removeObserver(itemEndObserver, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerItem)
        }
        itemEndObserver = nil
        self.isPlaying = false
        self.player = nil
        self.assetURL = nil
        self.playerItem = nil
        self.isPreparedToPlay = false
        self.currentTime = 0
        self.totalTime = 0
        self.bufferTime = 0
        self.isReadyToPlay = false
    }

    func replay() {
        
        self.seekToTime(time: 0) { (finished) in
            if finished {
                self.play()
            }
        }
    }
    
    func muted() {
        guard let isMuted = self.player?.isMuted else { return }
        self.isMuted = !isMuted
    }
    
    // 缩略图获取
    func thumbnailImageAtCurrentTime() ->UIImage? {
        guard let asset = asset else { return nil }
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        let expactedTime = playerItem?.currentTime() ?? .zero
        var cgImage: CGImage?
        
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        do {
            cgImage = try imageGenerator.copyCGImage(at: expactedTime, actualTime: nil)
        } catch let e  {
            print(e.localizedDescription)
        }
        if cgImage == nil {
            imageGenerator.requestedTimeToleranceBefore = .indefinite
            imageGenerator.requestedTimeToleranceAfter = .indefinite
            do {
                cgImage = try imageGenerator.copyCGImage(at: expactedTime, actualTime: nil)
            } catch let e  {
                print(e.localizedDescription)
            }
            
        }
        guard let _cgImage = cgImage else { return nil }
        let image = UIImage(cgImage: _cgImage)
        return image
        
    }
    
    // 滑动到指定时间
    func seekToTime(time: TimeInterval, completionHandler: ((Bool) -> Void)?) {
        if self.totalTime ?? 0 > 0 {
            let seekTime = CMTimeMake(value: Int64(time), timescale: 1)
            if let _completionHandler = completionHandler {
                player?.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: _completionHandler)
                
            }
        } else {
            self.seekTime = time
        }
    }
    
    // ------------ end ------------
    
    override init() {
        super.init()
        self.scalingModel = .aspectFit
        self.shouldAutoPlay = true
    }
    
    // 播放速度的切换
    func enableAudoTracks(enable: Bool, in playItem: AVPlayerItem) {
        for track in playItem.tracks {
            if track.assetTrack?.mediaType == AVMediaType.video  {
                track.isEnabled = enable
            }
        }
    }

    deinit {
//        print("\(self) deinit")
    }
}

extension QKAVPlayerManager {
    
    
    // MARK: - 初始化播放器
    func initializePlayer() {
        
        guard let assetURL = self.assetURL else { return }
        self.asset = AVURLAsset(url: assetURL, options: videoRequestHeader)
        self.playerItem = AVPlayerItem(asset: asset!)
        player = AVPlayer(playerItem: self.playerItem!)
        self.enableAudoTracks(enable: true, in: self.playerItem!)
        
        let presentView = self.view as? QKPlayerPresentView
        presentView?.player = self.player
        
        if #available(iOS 9, *) {
            // 在做视频列表的时候，暂停播放了，但是缓冲还是会继续加载。断续播放了好几个视频，就照成了不必要的流量消耗。
            // 最好的体验应该是暂停播放的同时也暂停缓冲加载，或者播放下一个视频的时候，暂停上一个视频的缓冲加载。
            // 暂停播放同时也暂停缓冲加载
            self.playerItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = false
        }
        
        if #available(iOS 10, *) {
            // 设置缓冲时间
            self.playerItem?.preferredForwardBufferDuration = 5
            // 自动等待，以最大限度减少停顿
            self.player?.automaticallyWaitsToMinimizeStalling = false
        }
        
        itemObserving()
    }
    
    // MARK: 添加视频的观察者
    func itemObserving() {
        
        playerItemObserver?.qkRemoveAllObservers()
        guard let _playerItem = self.playerItem else { return }
        playerItemObserver = QKObserverControl(target: _playerItem)
        playerItemObserver?.qkAddObserver(self, forKeyPath: kStatus, options: .new, context: nil)
        playerItemObserver?.qkAddObserver(self, forKeyPath: kLoadedTimeRanges, options: .new, context: nil)
        playerItemObserver?.qkAddObserver(self, forKeyPath: kPlaybackBufferEmpty, options: .new, context: nil)
        playerItemObserver?.qkAddObserver(self, forKeyPath: kPlaybackLikelyToKeepUp, options: .new, context: nil)
        playerItemObserver?.qkAddObserver(self, forKeyPath: kPresentationSize, options: .new, context: nil)
        // 从一个Float64的秒数和一个首选的时间刻度中制作一个CMTime。
        let interval = CMTimeMakeWithSeconds(self.timerRefreshInterVal, preferredTimescale: Int32(NSEC_PER_SEC))
        timerObserver = self.player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self](time) in
            guard let `self` = self else { return }
            let loadeRanges = self.playerItem?.seekableTimeRanges ?? []
            if loadeRanges.count > 0, let playerPlayTimeChange = self.playerPlayTimeChange { // 播放时间改变
                playerPlayTimeChange(self, self.currentTime ?? 0, self.totalTime ?? 0)
            }
        })
        
        // 播放完毕监听
        itemEndObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerItem, queue: .main, using: { [weak self](notice) in
            guard let `self` = self else { return }
            self.playState = .playStopped
            if let playerDidToEnd = self.playerDidToEnd {
                playerDidToEnd(self)
            }
        })
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        DispatchQueue.main.async {
        
            if keyPath == kStatus {
                if self.player?.currentItem?.status == AVPlayerItem.Status.readyToPlay { // 准备播放
                    if self.isReadyToPlay == false {
                        self.isReadyToPlay = true
                        self.loadState = .ok
                        if let playerReadyToPlay = self.playerReadyToPlay, let assetURL = self.assetURL {
                            playerReadyToPlay(self, assetURL)
                        }
                    }
                    if let seekTime = self.seekTime {
                        if self.shouldAutoPlay == true {
                            self.player?.pause()
                            self.seekToTime(time: seekTime) { (finished) in // 滑动到指定进度时间
                                if finished {
                                    if self.shouldAutoPlay == true { self.play() }
                                }
                            }
                            self.seekTime = 0
                        }
                    } else {
                        if self.shouldAutoPlay == true { self.play() }
                    }
                    self.player?.isMuted = self.isMuted ?? false // 播放器是否静音
                    let loadeRanges = self.playerItem?.seekableTimeRanges ?? [] // 时间范围集合 提供的范围顺序可能不连续
                    if loadeRanges.count > 0 {
                        if let playerPlayTimeChanged = self.playerPlayTimeChange {
                            playerPlayTimeChanged(self, self.currentTime ?? 0, self.totalTime ?? 0)
                        }
                    }
                } else if self.player?.currentItem?.status == AVPlayerItem.Status.failed {
                    self.playState = .playFailed
                    self.isPlaying = false
                    let error = self.player?.currentItem?.error
                    if let playerPlayFailed = self.playerPlayFaild { // 播放失败的回调
                        playerPlayFailed(self, error as Any)
                    }
                }
            } else if keyPath == kPlaybackBufferEmpty {
                // 当缓冲时空的时候
                if self.playerItem?.isPlaybackBufferEmpty == true {
                    self.loadState = .stalled 
                    self.bufferingSomeSecond()
                }
            } else if keyPath == kPlaybackLikelyToKeepUp {
                // 当缓冲OK时
                if self.playerItem?.isPlaybackLikelyToKeepUp == true {
                    self.loadState = .playable
                    self.isBuffering = false
                    if self.isPlaying == true {
                        self.player?.play()
                    }
                }
                
            } else if keyPath == kLoadedTimeRanges { // 加载时间范围
                let bufferTime = self.availableDuration()
                self.bufferTime = bufferTime // 记录缓冲的时间
                if let playerBufferTimeChanged = self.playerBufferTimeChanged {
                    playerBufferTimeChanged(self, bufferTime)
                }
            } else if keyPath == kPresentationSize { // 视图大小
                self.presentationSize = self.playerItem?.presentationSize
                if let presentationSizeChanged = self.presentationSizeChanged, let presentationSize = self.presentationSize {
                    presentationSizeChanged(self, presentationSize) // 回调
                }
            }
        }
    }
        
    // MARK: - 缓冲差时调用这里
    func bufferingSomeSecond() {
        // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
        if self.isBuffering || self.playState == QKPlayerPlaybackState.playStopped { return }
        // 没有网络也需要判断
        if QKReachabilityManager.shareManager.status == .notReachable { return }
        
        self.isBuffering = true
        
        // 需要暂停一下才播放，因为网络不好的情况下，时间在走，声音却播放不出来，效果特别差
        self.player?.pause()

    }
    
    // MARk: - 计算缓冲进度
    func availableDuration() ->TimeInterval {
        let timeRangeArray = self.playerItem?.loadedTimeRanges ?? [] //
        let currentTime = self.player?.currentTime()
        var isRange = false
        var aTimeRange: CMTimeRange?
        if timeRangeArray.count > 0 {
            aTimeRange = timeRangeArray.first?.timeRangeValue
            if let _aTimeRange = aTimeRange, let currentTime = currentTime {
                if CMTimeRangeContainsTime(_aTimeRange, time: currentTime) {
                    isRange = true
                }
            }
        }
        
        if isRange { // 如果有时间范围
            if let _aTimeRange = aTimeRange {
                let maxTime = CMTimeRangeGetEnd(_aTimeRange) // 获取结束时间
                let playableDuration = CMTimeGetSeconds(maxTime) // 获取缓冲大小
                if playableDuration > 0 {
                    return playableDuration
                }
            }
        }
        return 0
    }
        
}

