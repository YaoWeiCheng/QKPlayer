//
//  QKPlayerMediaPlayback.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/6.
//  Copyright © 2020 cyw. All rights reserved.
//

import Foundation
import UIKit

// 视频显示的模式跟图片的contentModel差不多
enum QKPlayerScalingMode {
    case none           // 不缩放
    case aspectFit      // 按比例缩放适应，不变形
    case aspectFill     // 是以原比例拉伸视频，直到两边屏幕都占满，但视频内容有部分就被切割了
    case fill           // 非统一比例。两种渲染尺寸将完全匹配可见的边界
}

// 播放状态
enum QKPlayerPlaybackState {
    case unknown        // 未知
    case playing        // 正在播放
    case paused         // 暂停
    case playFailed     // 播放失败
    case playStopped    // 停止播放
}

// 视频加载状态
enum QKPlayerLoadState: Int {
    case unkown     = 0
    case prepare    = 1
    case playable   = 2
    case ok         = 3 // 该状态下，播放器会自动播放
    case stalled    = 4 // 需要缓冲时状态
}

protocol QKPlayerMediaPlayback: NSObjectProtocol {
    
    var view: QKPlayerView? { get set }
    // 音量
    var volume: Float? { get set }
    // 播放器是否静音
    var isMuted: Bool? { get set }
    // 播放速度 0.5..2.0
    var rate: Float? { get set }
    // 当前播放时间
    var currentTime: TimeInterval? { get }
    // 播放总长
    var totalTime: TimeInterval? { get }
    // 缓冲时间
    var bufferTime: TimeInterval? { get }
    // 滑动时间
    var seekTime: TimeInterval? { get set }
    // 是否正在播放
    var isPlaying: Bool? { get }
    
    
    // 检查视频是否准备好播放
    var isPreparedToPlay: Bool? { get set }
    // 是否自动播放
    var shouldAutoPlay: Bool? { get set }
    // 播放的URL
    var assetURL: URL? { get set }
    // 控制器的尺寸
    var presentationSize: CGSize? { get }
    
    // 确定内容的缩放方式以适应视图。默认为none
    var scalingModel: QKPlayerScalingMode? { get set }
    
    // 播放回调状态
    var playState: QKPlayerPlaybackState? { get }
    
    // 播放加载状态
    var loadState: QKPlayerLoadState? { get }
    
    
    // 当播放器准备时调用
    var playerPrepareToPlay: ((_ asset: QKPlayerMediaPlayback, _ assetURL: URL) ->Void)? { get set }
    
    // 当播放器准备好调用
    var playerReadyToPlay: ((_ asset: QKPlayerMediaPlayback, _ assetURL: URL) ->Void)? { get set }
    
    // 当播放器进度发生改变时
    var playerPlayTimeChange: ((_ asset: QKPlayerMediaPlayback, _ currentTiem: TimeInterval, _ duration: TimeInterval) ->Void)? { get set }
    
    // 当播放缓冲发生变化时
    var playerBufferTimeChanged: ((_ asset: QKPlayerMediaPlayback, _ bufferTime: TimeInterval) ->Void)? { get set }
    
    // 当播放状态发生改变时
    var playerPlayStateChanged: ((_ asset: QKPlayerMediaPlayback, _ playState: QKPlayerPlaybackState) ->Void)? { get set }
    
    // 当播放加载状态发生改变时
    var playerLoadStateChanged: ((_ asset: QKPlayerMediaPlayback, _ loadState: QKPlayerLoadState) -> Void)? { get set }
    
    // 当播放失败时
    var playerPlayFaild: ((_ asset: QKPlayerMediaPlayback, _ error: Any) ->Void)? { get set }
    
    // 当播放结束时
    var playerDidToEnd: ((_ asset: QKPlayerMediaPlayback) ->Void)? { get set }
    
    // 当播放器视图的尺寸发生改变时
    var presentationSizeChanged: ((_ asset: QKPlayerMediaPlayback, _ size: CGSize) ->Void)? { get set }
    
    
    // 准备好当前播放条件
    func prepareToPlay()
    
    // 重新加载播放器
    func reloadPlayer()
    
    // 播放回调
    func play()
    
    // 暂停播放
    func pause()
    
    // 停止播放
    func stop()
    
    // 重播
    func replay()
    
    // 禁音
    func muted()
    
    // 获取当前时间的视频封面图
    func thumbnailImageAtCurrentTime() ->UIImage?
    
    // 调整播放时间进度并回调
    func seekToTime(time: TimeInterval, completionHandler: ((Bool)->Void)?)
}
