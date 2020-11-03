//
//  QKPlayerMediaControl.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/10.
//  Copyright © 2020 cyw. All rights reserved.
//

import Foundation
import UIKit




protocol QKPlayerMediaControl: NSObjectProtocol {
    
    var player: QKPlayerController? { get set }
    
    /// option
    
    /// 播放器准备播放
    func videoPlayer(playerControl: QKPlayerController, prepareToPlayer assetURL: URL)
    
    /// 播放状态发生改变
    func videoPlayer(playerControl: QKPlayerController, playStateChanged state: QKPlayerPlaybackState)
    
    /// 播放加载状态发生改变时
    func videoPlayer(playerControl: QKPlayerController, loadStateChange state: QKPlayerLoadState)
    
    /// progress
    
    /// 播放回调时
    /// - Parameters:
    ///   - playerControl: 播放控制器
    ///   - currentTime: 播放当前时间
    ///   - totalTime: 总时间
    func videoPlayer(playerControl: QKPlayerController, currentTime: TimeInterval, totalTime: TimeInterval)
    
    /// 当播放缓存发生改变时
    /// - Parameters:
    ///   - playerControl: 播放控制器
    ///   - bufferTime: 缓冲时间
    func videoPlayer(playerControl: QKPlayerController, bufferTime: TimeInterval)
    
    /// 当拖拽进度条，发生时间改变时
    /// - Parameters:
    ///   - seekTime: 跳转的时间
    ///   - totalTime: 总时间
    func videoPlayer(playerControl: QKPlayerController, dargging seekTime: TimeInterval, totalTime: TimeInterval)
    
    /// 播放结束时
    func videoPlayerToEnd(playerControl: QKPlayerController)
    
    /// 播放失败
    func videPlayerToFaild(playerControl: QKPlayerController, error: Any)
    
    /// 尺寸改变
    func videoPlayer(playerControl: QKPlayerController, presentationSizeChanged: CGSize)
    
    
    // MARK: - Gesture
    
    /// 单击回调
    func gestureSingleTap(gestureControl: QKPlayerGestureControl)
    
    /// 双击回调
    func gestureDoubleTap(gestureControl: QKPlayerGestureControl)
    
    
    // MARK: - Screen rotation
    /// 屏幕 即将更改模式
    func videoPlayer(playerControl: QKPlayerController, orientationWillChange observer: QKOrientationObserver)
    /// 屏幕 更改模式完毕
    func videoPlayer(playerControl: QKPlayerController, orientationDidChanged observer: QKOrientationObserver)
    
    
    // MARK: - ScrollView
    /// 当播放器即将显示在scrollView时
    func playerWillAppearInScrollView(playerControl: QKPlayerController)
    /// 当播放器已经显示在scrollView时
    func playerDidAppearInScrollView(playerControl: QKPlayerController)
    /// 当播放器即将消失时
    func playerWillDisappearInScrollView(playerControl: QKPlayerController)
    /// 当播放器已经消失时
    func playerDidDisapperaInScrollView(playerControl: QKPlayerController)
    /// 当播放器显示中
    func playerApperaingInscrollView(playerControl: QKPlayerController, playerApperaPercent: CGFloat)
    /// 正在消失进度
    func playerDisapperingInScrollView(playerControl: QKPlayerController, playerDisapperaPercent: CGFloat)
    
}

/// 可选
extension QKPlayerMediaControl {
    
    // 播放器准备播放
    func videoPlayer(playerControl: QKPlayerController, prepareToPlayer assetURL: URL) { }
    
    // 播放状态发生改变
    func videoPlayer(playerControl: QKPlayerController, playStateChanged state: QKPlayerPlaybackState) { }
    
    /// 播放加载状态发生改变时
    func videoPlayer(playerControl: QKPlayerController, loadStateChange state: QKPlayerLoadState) {}
    
    /// 播放回调时
    func videoPlayer(playerControl: QKPlayerController, currentTime: TimeInterval, totalTime: TimeInterval) {}
    
    /// 当播放缓存发生改变时
    func videoPlayer(playerControl: QKPlayerController, bufferTime: TimeInterval) {}
    
    /// 当拖拽进度条，发生时间改变时
    func videoPlayer(playerControl: QKPlayerController, dargging seekTime: TimeInterval, totalTime: TimeInterval) {}
    
    /// 播放结束时
    func videoPlayerToEnd(playerControl: QKPlayerController) {}
    
    /// 播放失败
    func videPlayerToFaild(playerControl: QKPlayerController, error: Any) {}
    
    /// 尺寸改变
    func videoPlayer(playerControl: QKPlayerController, presentationSizeChanged: CGSize) {}
    
    // MARK: - Gesture
    
    /// 单击回调
    func gestureSingleTap(gestureControl: QKPlayerGestureControl) {}
    
    /// 双击回调
    func gestureDoubleTap(gestureControl: QKPlayerGestureControl) {}
    
    /// 屏幕 即将更改模式
    func videoPlayer(playerControl: QKPlayerController, orientationWillChange observer: QKOrientationObserver) {}
    /// 屏幕 更改模式完毕
    func videoPlayer(playerControl: QKPlayerController, orientationDidChanged observer: QKOrientationObserver) {}
    
    
    // MARK: - ScrollView
    /// 当播放器即将显示在scrollView时
    func playerWillAppearInScrollView(playerControl: QKPlayerController) {}
    /// 当播放器已经显示在scrollView时
    func playerDidAppearInScrollView(playerControl: QKPlayerController) {}
    /// 当播放器即将消失时
    func playerWillDisappearInScrollView(playerControl: QKPlayerController) {}
    /// 当播放器已经消失时
    func playerDidDisapperaInScrollView(playerControl: QKPlayerController) {}
    /// 当播放器显示中
    func playerApperaingInscrollView(playerControl: QKPlayerController, playerApperaPercent: CGFloat) {}
    /// 正在消失进度
    func playerDisapperingInScrollView(playerControl: QKPlayerController, playerDisapperaPercent: CGFloat) {}
}
