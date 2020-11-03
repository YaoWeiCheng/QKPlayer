//
//  QKPlayerController+ScrollView.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/17.
//  Copyright © 2020 cyw. All rights reserved.
//

import Foundation
import UIKit

extension QKPlayerController {
    
    struct QKPlayerControllerScrollView {
        static var scrollView = "scrollView"
        static var isShouldAutoPlay = "isShouldAutoPlay"
        static var isWWANAutoPlay = "isWWANAutoPlay"
        static var playingIndexPath = "playingIndexPath"
        static var shouldPlayIndexPath = "shouldPlayIndexPath"
        static var containerViewTag = "containerViewTag"
        static var stopWhileNotVisible = "stopWhileNotVisible"
        static var playerDisapperaPercent = "playerDisapperaPercent"
        static var playerApperaPercent = "playerApperaPercent"
    }
    
    public weak var scrollView: UIScrollView? {
        get {
            return objc_getAssociatedObject(self, &QKPlayerControllerScrollView.scrollView) as? UIScrollView
        }
        set {
            objc_setAssociatedObject(self, &QKPlayerControllerScrollView.scrollView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            newValue?.playerWillAppearInScrollView = { [weak self](indexpath) in
                guard let `self` = self else { return }
                if self.isFullScreen { return }
                self.controlView?.playerDidAppearInScrollView(playerControl: self)
            }
            newValue?.playerDidAppearInScrollView = { [weak self](IndexPath) in
                guard let `self` = self else { return }
                if self.isFullScreen { return }
                self.controlView?.playerDidAppearInScrollView(playerControl: self)
            }
            newValue?.playerWillDisappearInScrollView = { [weak self](indexPath) in
                guard let `self` = self else { return }
                if self.isFullScreen { return }
                self.controlView?.playerWillDisappearInScrollView(playerControl: self)
            }
            newValue?.playerDidDisappearInScrollView = { [weak self](indexPath) in
                guard let `self` = self else { return }
                if self.isFullScreen { return }
                self.controlView?.playerDidDisapperaInScrollView(playerControl: self)
                
                if self.stopWhileNotVisible == true {
                    if self.containerType == .view {
                        self.stopCurrentPlayingView()
                    } else if self.containerType == .cell {
                        self.stopCurrentPlayingCell()
                    }
                }
            }
            
            newValue?.playerAppearingInScrollView = { [weak self](indexPath, playerApperaPercent) in
                guard let `self` = self else { return }
                self.controlView?.playerApperaingInscrollView(playerControl: self, playerApperaPercent: playerApperaPercent)
            }
            
            newValue?.playerDisapperingInScrollView = { [weak self](indexPath, playerDisapperaPercent) in
                guard let `self` = self else { return }
                if self.isFullScreen { return }
                self.controlView?.playerDisapperingInScrollView(playerControl: self, playerDisapperaPercent: playerDisapperaPercent)
                if playerDisapperaPercent >= self.playerDisapperaPercent ?? 0 {
                    if self.stopWhileNotVisible == true {
                        if self.containerType == .view {
                            self.stopCurrentPlayingView()
                        } else if self.containerType == .cell {
                            self.stopCurrentPlayingCell()
                        }
                    }
                }
            }
//            newValue?.playerShouldPlayInScrollView = { [weak self](indexPath) in
//
//            }
        }
    }
    
    public var isShouldAutoPlay: Bool {
        get {
            return objc_getAssociatedObject(self, &QKPlayerControllerScrollView.isShouldAutoPlay) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &QKPlayerControllerScrollView.isShouldAutoPlay, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.scrollView?.isShouldAutoPlay = newValue
        }
    }

    public var isWWANAutoPlay: Bool {
        get {
            return objc_getAssociatedObject(self, &QKPlayerControllerScrollView.isWWANAutoPlay) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &QKPlayerControllerScrollView.isWWANAutoPlay, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.scrollView?.isWWANAutoPlay = newValue
        }
    }
    
    private(set) var playingIndexPath: IndexPath? {
        get {
            return objc_getAssociatedObject(self, &QKPlayerControllerScrollView.playingIndexPath) as? IndexPath
        }
        set {
            objc_setAssociatedObject(self, &QKPlayerControllerScrollView.playingIndexPath, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let indexPath = newValue, let containerViewTag = self.containerViewTag, let view = self.currentPlayerManager?.view {
                self.stop()
                guard let cell = self.scrollView?.qk_getCell(at: indexPath) else { return }
                self.containerView = cell.viewWithTag(containerViewTag)
                self.orientationObserver?.updateRotateView(rotateView: view, cell: cell, playerViewTag: containerViewTag)
                self.scrollView?.playingIndexPath = indexPath
                layoutPlayerSubViews()
            } else {
                self.scrollView?.playingIndexPath = newValue
            }
        }
    }
    
    private(set) var shouldPlayIndexPath: IndexPath? {
        get {
            return objc_getAssociatedObject(self, &QKPlayerControllerScrollView.shouldPlayIndexPath) as? IndexPath
        }
        set {
            objc_setAssociatedObject(self, &QKPlayerControllerScrollView.shouldPlayIndexPath, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.scrollView?.shouldPlayIndexPath = newValue
        }
    }
    
    var containerViewTag: Int? {
        get {
            return objc_getAssociatedObject(self, &QKPlayerControllerScrollView.containerViewTag) as? Int
        }
        set {
            objc_setAssociatedObject(self, &QKPlayerControllerScrollView.containerViewTag, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.scrollView?.containerViewTag = newValue
        }
    }
    // 默认true
    public var stopWhileNotVisible: Bool {
        get {
            return objc_getAssociatedObject(self, &QKPlayerControllerScrollView.stopWhileNotVisible) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &QKPlayerControllerScrollView.stopWhileNotVisible, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.scrollView?.stopWhileNotVisible = newValue
        }
    }
    
    // 当前播放器滚动从屏幕上滑出百分比。
    public var playerDisapperaPercent: CGFloat? {
        get {
            return objc_getAssociatedObject(self, &QKPlayerControllerScrollView.playerDisapperaPercent) as? CGFloat ?? 0.5
        }
        set {
            objc_setAssociatedObject(self, &QKPlayerControllerScrollView.playerDisapperaPercent, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.scrollView?.playerDisapperaPercent = newValue
        }
    }
    
    // 滑入百分比
    public var playerApperaPercent: CGFloat? {
        get {
            return objc_getAssociatedObject(self, &QKPlayerControllerScrollView.playerApperaPercent) as? CGFloat ?? 0.0
        }
        set {
            objc_setAssociatedObject(self, &QKPlayerControllerScrollView.playerApperaPercent, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.scrollView?.playerApperaPercent = newValue
        }
    }
    
    public func filterShouldPlayCellWhileScrolled(handler: @escaping ((IndexPath)->Void)) {
        self.scrollView?.filterShouldPlayCellWhileScrolled(handler: handler)
    }
    
    public func filterShouldPlayCellWhileScrolling(handler: @escaping ((IndexPath)->Void)) {
        self.scrollView?.filterShouldPlayCellWhileScrolling(handler: handler)
    }
    
    public func playTheIndexPath(indexPath: IndexPath) {
        self.playingIndexPath = indexPath
        var assetURL: URL?
        if assetURLs?.count ?? 0 > 0 {
            assetURL = self.assetURLs?[indexPath.row]
            self.currentPlayIndex = indexPath.row
        }
        self.assetURL = assetURL
    }

}
