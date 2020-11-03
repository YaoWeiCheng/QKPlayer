//
//  QKPlayerController.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/7.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class QKPlayerController: NSObject {
    
    // MARK: - Private Property
    
    // 手势
    private lazy var gestureControl: QKPlayerGestureControl = {
        let gestureControl = QKPlayerGestureControl()
        // 单击
        gestureControl.singleTapedCallback = { [weak self](gestureControl)in
            self?.controlView?.gestureSingleTap(gestureControl: gestureControl)
        }
        // 双击
        gestureControl.doubleTapedCallback = { [weak self](gestureControl) in
            self?.controlView?.gestureDoubleTap(gestureControl: gestureControl)
        }
        return gestureControl
    }()
    // 音量
    private var volumeSlider: UISlider?
    
    private var _currentPlayerManager: QKPlayerMediaPlayback?

    private var _containerType = QKPlayerContainerType.view
    // 系统监听
    private lazy var notification: QKPlayerNotification = {
        let notification = QKPlayerNotification()
        notification.willResignActiveCallback = { [weak self](notice) in
            guard let `self` = self else { return }
            guard self.isViewControllerDisappear == true else { return }
            if self.pauseWhenAppResignActive, self.currentPlayerManager?.isPlaying == true {
                self.pauseByEvent = true
            }
            UIApplication.shared.keyWindow?.endEditing(true)
            if self.pauseWhenAppResignActive == false {
                // 静默模式，即使在后台，依然可以播放声音
                UIApplication.shared.beginReceivingRemoteControlEvents()
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
        notification.didBecomeActiveCallback = { [weak self](notice) in
            guard let `self` = self else { return }
            guard self.isViewControllerDisappear == true else { return }
            if self.pauseByEvent == true {
                self.pauseByEvent = false
            }
        }
        notification.oldDeviceUnavailable = { [weak self](notification) in
            guard let `self` = self else { return }
            if self.currentPlayerManager?.isPlaying == true {
                self.currentPlayerManager?.play()
            }
        }
        
       return notification
    }()

    // MARK: - Public Property
    
    public weak var containerView: UIView? {

        didSet {
            if self.containerView == nil { return }
            self.containerView?.isUserInteractionEnabled = true
            if let _ = scrollView {
                scrollView?.containerView = containerView
            }
            self.layoutPlayerSubViews()
        }
    }

    // 播放器管理
    public weak var currentPlayerManager: QKPlayerMediaPlayback? {
        set {
            _currentPlayerManager = newValue
            if _currentPlayerManager?.isPreparedToPlay == true {
                _currentPlayerManager?.stop()
                _currentPlayerManager?.view?.removeFromSuperview()
                
                if let controlView = _currentPlayerManager?.view {
                    self.gestureControl.removeGestureToView(targetView: controlView)
                }
            }
            _currentPlayerManager?.view?.isHidden = true
            guard let controlView = currentPlayerManager?.view else { return }
            self.gestureControl.addGestureToView(targetView: controlView)
            
            playerManagerCallback()
            if let containerView = self.containerView {
                self.orientationObserver?.updateRotateView(rotateView: controlView, containerView: containerView)
            }
            self.controlView?.player = self
            self.layoutPlayerSubViews()
        }
        get {
            return _currentPlayerManager
        }
    }

    // 控制代理view
    public weak var controlView: (UIView & QKPlayerMediaControl)? {
        didSet {
            self.controlView?.player = self
            self.layoutPlayerSubViews()
        }
    }
    
    // 播放器的容器类型
    public var containerType: QKPlayerContainerType {
        set {
            if let _ = self.scrollView {
                self.scrollView?.containerType = newValue
            }
            _containerType = newValue
        }
        get {
            return _containerType
        }
    }

    // MARK: - Method
    
    func configureVolum() {
        
        let volumeView = MPVolumeView()
        self.volumeSlider = nil
        for item in volumeView.subviews {
            if item.self.isKind(of: UISlider.self) {
                self.volumeSlider = item as? UISlider
                break
            }
        }
    }
    
    deinit {
//        print("\(self) deinit")
        self.currentPlayerManager?.stop()
    }

    
    func initialize() {
        QKReachabilityManager.shareManager.startNetworkReachabilityObserver()
        configureVolum()
    }
    
    init(playerManager: QKPlayerMediaPlayback, containerView: UIView) {
        super.init()
        initialize()
        self.containerView = containerView
        self.currentPlayerManager = playerManager
    }
    
    // MARK: - scrollView Init
    init(scrollView: UIScrollView, playerManager: QKPlayerMediaPlayback, containerViewTag: Int) {
        super.init()
        initialize()
        self.scrollView = scrollView
        self.containerViewTag = containerViewTag
        self.currentPlayerManager = playerManager
        self.containerType = .cell
    }
    
    // MARK: - Private Method
    
    func playerManagerCallback() {
        
        self.currentPlayerManager?.playerPrepareToPlay = { [weak self](asset, assetURL) in
            guard let `self` = self else { return }
            self.currentPlayerManager?.view?.isHidden = false
            self.notification.addNotification()
            if let scrollView = self.scrollView {
                scrollView.stopPlay = false
            }
            self.layoutPlayerSubViews()
            if let playerPrepareToPlay = self.playerPrepareToPlay {
                playerPrepareToPlay(asset, assetURL)
            }
            self.controlView?.videoPlayer(playerControl: self, prepareToPlayer: assetURL)
        }
        
        self.currentPlayerManager?.playerReadyToPlay = { [weak self](asset, assetURL) in
            guard let `self` = self else { return }
            if let playerReadyToPlay = self.playerReadyToPlay {
                playerReadyToPlay(asset, assetURL)
            }
            
            if self.customAVAudioSession == false {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, options: .allowBluetooth)
                    try AVAudioSession.sharedInstance().setMode(.moviePlayback)
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch let error {
                    print(error.localizedDescription)
                }
            }
            if self.isViewControllerDisappear == true {
                self.pauseByEvent = true
            }
        }
        
        self.currentPlayerManager?.playerPlayTimeChange = { [weak self](asset, currentTime, totalTime) in
            guard let `self` = self else { return }
            self.controlView?.videoPlayer(playerControl: self, currentTime: currentTime, totalTime: totalTime)
        }
        
        self.currentPlayerManager?.playerBufferTimeChanged = { [weak self](asset, bufferTimer) in
            guard let `self` = self else { return }
            self.controlView?.videoPlayer(playerControl: self, bufferTime: bufferTimer)
        }
        
        self.currentPlayerManager?.playerPlayStateChanged = { [weak self](asset, playState) in
            guard let `self` = self else { return }
            self.controlView?.videoPlayer(playerControl: self, playStateChanged: playState)
        }
        
        self.currentPlayerManager?.playerLoadStateChanged = { [weak self](asset, loadState) in
            guard let `self` = self else { return }
            self.controlView?.videoPlayer(playerControl: self, loadStateChange: loadState)
        }
        
        // 播放结束回调
        self.currentPlayerManager?.playerDidToEnd = { [weak self](asset) in
            guard let `self` = self else { return }
            if let playerDidToEnd = self.playerDidToEnd {
                playerDidToEnd(asset)
            }
            self.controlView?.videoPlayerToEnd(playerControl: self)
        }
        
        self.currentPlayerManager?.playerPlayFaild = { [weak self](asset, error) in
            guard let `self` = self else { return }
            self.controlView?.videPlayerToFaild(playerControl: self, error: error)
        }
        
        self.currentPlayerManager?.presentationSizeChanged = { [weak self](asset, size) in
            guard let `self` = self else { return }
            // 代理回调视图大小
            self.controlView?.videoPlayer(playerControl: self, presentationSizeChanged: size)
        }
        
    }
    
    // MARK: - 设置subViews
    func layoutPlayerSubViews() {
        
        if let containerView = self.containerView, let presentView = self.currentPlayerManager?.view, let controlView = self.controlView {
            var superView: UIView?
            if self.isFullScreen == true {
                superView = self.orientationObserver?.fullScreenContainerView
            } else {
                superView = containerView
            }
            superView?.addSubview(presentView)
            presentView.addSubview(controlView)
            
            self.currentPlayerManager?.view?.frame = superView?.bounds ?? .zero
            self.currentPlayerManager?.view?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.controlView?.frame = self.currentPlayerManager?.view?.bounds ?? .zero
            self.controlView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.orientationObserver?.updateRotateView(rotateView: presentView, containerView: containerView)
            
        }
        
    }
}

// MARK: - PlayerTimeControl

extension QKPlayerController {
    
    // 当前时间
    public var currentTime: TimeInterval? {
        get {
            return self.currentPlayerManager?.currentTime
        }
    }
    
    // 总播放时间
    public var totalTime: TimeInterval? {
        get {
            return self.currentPlayerManager?.totalTime
        }
    }
    // 缓冲时间
    public var bufferTime: TimeInterval? {
        get {
            return self.currentPlayerManager?.bufferTime
        }
    }
    // 播放进度
    public var progress: CGFloat {
        get {
            return CGFloat((self.currentTime ?? 0) / (self.totalTime ?? 0))
        }
    }
    // 缓冲进度
    public var bufferProgress: CGFloat {
        get {
            return CGFloat((self.bufferTime ?? 0) / (self.totalTime ?? 0))
        }
    }
    
    // 修改时间
    func seekTime(time: TimeInterval, complectionHandler: ((Bool)->Void)?) {
        self.currentPlayerManager?.seekToTime(time: time, completionHandler: complectionHandler)
    }
}

// QKPlayerPlaybackControl
extension QKPlayerController {
    
    struct AssociationPlayerController {
        static var resumePlayRecord = "resumePlayRecord"
        static var volume = "volume"
        static var lastVolumeValue = "lastVolumeValue"
        static var isMuted = "isMuted"
        static var brightness = "brightness"
        static var assetURL = "assetURL"
        static var assetURLs = "assetURLs"
        static var currentPlayIndex = "currentPlayIndex"
        static var pauseWhenAppResignActive = "pauseWhenAppResignActive"
        static var pauseByEvent = "pauseByEvent"
        static var isViewControllerDisappear = "isViewControllerDisappear"
        static var customAVAudioSession = "customAVAudioSession"
        static var playerPrepareToPlay = "playerPrepareToPlay"
        static var playerReadyToPlay = "playerReadyToPlay"
        static var playerPlayTimeChanged = "playerPlayTimeChanged"
        static var playerBufferTimeChanged = "playerBufferTimeChanged"
        static var playerPlayStateChanged = "playerPlayStateChanged"
        static var playerLoadStateChanged = "playerLoadStateChanged"
        static var playerPlayFaild = "playerPlayFaild"
        static var playerDidToEnd = "playerDidToEnd"
        static var presentationSizeChanged = "presentationSizeChanged"
        
    }
    
    // 继续播放记录 默认false
    // 储存回放记录
//    public var resumePlayRecord: Bool {
//        get {
//            return (objc_getAssociatedObject(self, &AssociationPlayerController.resumePlayRecord) as? Bool) ?? false
//        }
//        set {
//            objc_setAssociatedObject(self, &AssociationPlayerController.resumePlayRecord, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
    
    // 音量
    public var volume: CGFloat? {
        get {
            var _volume: CGFloat = CGFloat(self.volumeSlider?.value ?? 0) // 通过volumeViewSlider获取
            if _volume == 0 {
                _volume = CGFloat(AVAudioSession.sharedInstance().outputVolume)
            }
            return _volume
        }
        set {
            let _volume = min(max(0, newValue ?? 0), 1)
            objc_setAssociatedObject(self, &AssociationPlayerController.volume, _volume, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.volumeSlider?.value = Float(_volume)
        }
    }
    // 上一次的音量，禁音前的记录
    private var lastVolumeValue: CGFloat? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.lastVolumeValue) as? CGFloat
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.lastVolumeValue, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 设备静音
    public var isMuted: Bool? {
        get {
            return self.volume == 0
        }
        set {
            if newValue == true {
                if self.volumeSlider?.value ?? 0 > 0 {
                    self.lastVolumeValue = CGFloat(self.volumeSlider?.value ?? 0)
                }
                self.volumeSlider?.value = 0
            } else {
                self.volumeSlider?.value = Float(self.lastVolumeValue ?? 0)
            }
        }
    }
    
    // 屏幕亮度 0..1
    public var brightness: CGFloat? {
        get {
            return UIScreen.main.brightness
        }
        set {
            let _max = max(0, newValue ?? 0)
            let _brightness = min(_max, 1)
            objc_setAssociatedObject(self, &AssociationPlayerController.brightness, _brightness, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            UIScreen.main.brightness = _brightness
        }
    }
    
    // 播放Url
    public var assetURL: URL? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.assetURL) as? URL
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.assetURL, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.currentPlayerManager?.assetURL = newValue
        }
    }
    
    // 播放urls数组
    public var assetURLs: [URL]? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.assetURLs) as? [URL]
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.assetURLs, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 当前播放索引
    public var currentPlayIndex: Int {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.currentPlayIndex) as? Int ?? 0
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.currentPlayIndex, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    // 如果是，则当收到“UIApplicationWillResignActivationNotification”通知时，播放器将被调用pause方法。默认true
    public var pauseWhenAppResignActive: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.pauseWhenAppResignActive) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.pauseWhenAppResignActive, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 当正在播放的时候，因其他原因导致需要暂停状态，例如跳转到下一个vc
    public var pauseByEvent: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.pauseByEvent) as? Bool
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.pauseByEvent, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue == true { // true 的话就暂停
                self.currentPlayerManager?.pause()
            } else { // false就播放
                self.currentPlayerManager?.play()
            }
        }
    }
    
    // 记录播放控制器消失，不是被释放的时候
    public var isViewControllerDisappear: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.isViewControllerDisappear) as? Bool
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.isViewControllerDisappear, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if let _ = self.scrollView {
                self.scrollView?.isViewControllerDisappear = newValue
            }
            guard self.currentPlayerManager?.isPreparedToPlay == true else { return }
            if newValue != nil, newValue == true {
                if currentPlayerManager?.isPlaying == true {
                    self.pauseByEvent = true
                }
            } else {
                if self.pauseByEvent == true {
                    self.pauseByEvent = false
                }
            }
        }
    }
    
    // 自定义 AVAudioSession
    public var customAVAudioSession: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.customAVAudioSession) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.customAVAudioSession, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if newValue == true {
                self.currentPlayerManager?.isPlaying == true ? self.pauseByEvent = true : nil
            } else {
                self.pauseByEvent = false
            }
        }
    }
    
    // 准备播放时回调
    public var playerPrepareToPlay: ((QKPlayerMediaPlayback, URL)->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.playerReadyToPlay) as? ((QKPlayerMediaPlayback, URL)->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.playerReadyToPlay, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 准备好播放时
    public var playerReadyToPlay: ((QKPlayerMediaPlayback, URL) ->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.playerReadyToPlay) as? ((QKPlayerMediaPlayback, URL) ->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.playerReadyToPlay, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 播放器进度发生改变时
    public var playerPlayTimeChanged: ((QKPlayerMediaPlayback,  _ currentTiem: TimeInterval, _ duration: TimeInterval) ->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.playerPlayTimeChanged) as? ((QKPlayerMediaPlayback,  _ currentTiem: TimeInterval, _ duration: TimeInterval) ->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.playerPlayTimeChanged, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 当播放缓冲发生变化时
    public var playerBufferTimeChanged: ((_ asset: QKPlayerMediaPlayback, _ bufferTime: TimeInterval) ->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.playerBufferTimeChanged) as? ((_ asset: QKPlayerMediaPlayback, _ bufferTime: TimeInterval) ->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.playerBufferTimeChanged, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 当播放状态发生改变时
    public var playerPlayStateChanged: ((_ asset: QKPlayerMediaPlayback, _ playState: QKPlayerPlaybackState) ->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.playerPlayStateChanged) as? ((_ asset: QKPlayerMediaPlayback, _ playState: QKPlayerPlaybackState) ->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.playerPlayStateChanged, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
    }
    
    // 当播放加载状态发生改变时
    public var playerLoadStateChanged: ((_ asset: QKPlayerMediaPlayback, _ loadState: QKPlayerLoadState) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.playerLoadStateChanged) as? ((_ asset: QKPlayerMediaPlayback, _ loadState: QKPlayerLoadState) -> Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.playerLoadStateChanged, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 当播放失败时
    public var playerPlayFaild: ((_ asset: QKPlayerMediaPlayback, _ error: Any) ->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.playerPlayFaild) as? ((_ asset: QKPlayerMediaPlayback, _ error: Any) ->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.playerPlayFaild, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
    }
    
    // 当播放结束时
    public var playerDidToEnd: ((_ asset: QKPlayerMediaPlayback) ->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.playerDidToEnd) as? ((_ asset: QKPlayerMediaPlayback) ->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.playerDidToEnd, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 当播放器视图的尺寸发生改变时
    public var presentationSizeChanged: ((_ asset: QKPlayerMediaPlayback, _ size: CGSize) ->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationPlayerController.presentationSizeChanged) as? ((_ asset: QKPlayerMediaPlayback, _ size: CGSize) ->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationPlayerController.presentationSizeChanged, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    // MARK: - 播放指定索引
    public func playerToIndex(_ index: Int) {
        guard self.assetURLs?.count ?? 0 > 0, let count = self.assetURLs?.count else { return }
        if index > count { return }
        let url = self.assetURLs?[index]
        self.assetURL = url
    }
    
    // MARK: - 停止播放
    public func stop() {
        self.notification.removeNotification()
        self.currentPlayerManager?.stop()
        self.currentPlayerManager?.view?.removeFromSuperview()
    }
    
    // MARK: - 替换播放管理器
    public func replaceCurrentPlayerManager(_ manager: QKPlayerMediaPlayback) {
        self.currentPlayerManager = manager
    }
    
    // MARK: - 停止当前view上的播放器
    public func stopCurrentPlayingView() {
        if let _ = self.containerView {
            stop()
        }
    }
    
    // MARK: - 停止当前cell上的正在播放的播放器
    public func stopCurrentPlayingCell() {
        if let _ = self.scrollView?.playingIndexPath {
            stop()
        }
    }
}
