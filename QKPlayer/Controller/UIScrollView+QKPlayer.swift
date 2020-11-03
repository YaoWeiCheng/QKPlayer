//
//  UIScrollView+QKPlayer.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/10.
//  Copyright © 2020 cyw. All rights reserved.
//

import Foundation
import UIKit

enum QKPlayerContainerType {
    case view
    case cell
}

enum QKPlayerScrollDirection {
    case none
    case up
    case bottom
    case left
    case right
}

enum QKPlayerScrollViewDirection: Int {
    case vertical       = 0
    case horizontal     = 1
}


extension UIScrollView {
    
    struct AssociationScrollView {
        static var lastOffsetY = "lastOffsetY"
        static var lastOffsetX = "lastOffsetX"
        static var qk_scrollViewDirection = "qk_scrollViewDirection"
        static var qk_scrollDirection = "qk_scrollDirection"
    }
    
    //
    private(set) var lastOffsetY: CGFloat {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollView.lastOffsetY) as? CGFloat ?? 0
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollView.lastOffsetY, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private(set) var lastOffsetX: CGFloat {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollView.lastOffsetX) as? CGFloat ?? 0
        }
        set {
            return objc_setAssociatedObject(self, &AssociationScrollView.lastOffsetX, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 设置滑动方向
    var qk_scrollViewDirection: QKPlayerScrollViewDirection {
        get {
            let viewDirection = objc_getAssociatedObject(self, &AssociationScrollView.qk_scrollViewDirection) as? QKPlayerScrollViewDirection
            return viewDirection ?? QKPlayerScrollViewDirection.vertical
        }
        set {
            return objc_setAssociatedObject(self, &AssociationScrollView.qk_scrollViewDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 拖动滑向的方向
    var qk_scrollDirection: QKPlayerScrollDirection {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollView.qk_scrollDirection) as? QKPlayerScrollDirection ?? .none
        }
        set {
            return objc_setAssociatedObject(self, &AssociationScrollView.qk_scrollDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 根据索引获取cell
    func qk_getCell(at indexPath: IndexPath) ->UIView? {
        if _isTableView() {
            let tableView = self as! UITableView
            let cell = tableView.cellForRow(at: indexPath)
            return cell
        } else if _isCollectionView() {
            let collectionView = self as! UICollectionView
            let cell = collectionView.cellForItem(at: indexPath)
            return cell
        }
        return nil
    }
    // 获取当前cell的索引
    func qk_getIndexPath(for cell: UIView) ->IndexPath? {
        if _isTableView() {
            guard cell.isKind(of: UITableViewCell.self) else { return nil }
            let tableView = self as! UITableView
            let indexPath = tableView.indexPath(for: cell as! UITableViewCell)
            return indexPath
        } else if _isCollectionView() {
            guard cell.isKind(of: UICollectionViewCell.self) else { return nil }
            let collectionView = self as! UICollectionView
            let indexPath = collectionView.indexPath(for: cell as! UICollectionViewCell)
            return indexPath
        }
        return nil
    }
    
    // 滑动结束
    func qk_scrollViewDidEndDecelerating() {
        let scrollToScrollStop = !self.isTracking && !self.isDragging && !self.isDecelerating
        if scrollToScrollStop == true {
            _scrollViewDidStopScroll()
        }
    }
    
    // 拖动结束
    func scrollViewDidEndDragging(will decelerate: Bool) {
        if !decelerate {
            let dragToDragStop = self.isTracking && !self.isDragging && !self.isDecelerating
            if dragToDragStop {
                _scrollViewDidStopScroll()
            }
        }
    }
    
    // 滑动到顶部
    func qk_scrollViewDidScrollToTop() {
        _scrollViewDidStopScroll()
    }
    
    func qk_scrollViewDidScroll() {
        if self.qk_scrollViewDirection == .vertical {
            _findCorrectCellWhenScrollViewDirectionVertical(handler: nil)
            _scrollViewScrollingDirectionVertical()
        } else {
            _findCorrectCellWhenScrollViewDirectionHorizontal(handler: nil)
            _scrollViewScrollingDirectionHorizontal()
        }
    }
    
    func qk_scrollViewWillBeginDragging() {
        _scrollViewBeginDragging()
    }
    
    // MARK: - Private method
    
    func _scrollViewDidStopScroll() {
        self.qk_scrollDirection = .none
        self.filterShouldPlayCellWhileScrolled { [weak self](indexPath) in
            guard let `self` = self else { return }
            if let scrollViewDidEndScrollingCallback = self.scrollViewDidEndScrollingCallback {
                scrollViewDidEndScrollingCallback(indexPath)
            }
        }
        
    }
    
    // 开始拖动
    func _scrollViewBeginDragging() {
        if self.qk_scrollViewDirection == .vertical {
            self.lastOffsetY = self.contentOffset.y // 记录y轴开始坐标
        } else {
            self.lastOffsetX = self.contentOffset.x // 记录x轴
        }
    }
    
    // 竖方向时 滑动进度
    func _scrollViewScrollingDirectionVertical() {
        let offsetY = self.contentOffset.y
        self.qk_scrollDirection = (offsetY - self.lastOffsetY) > 0 ? .up : .bottom
        self.lastOffsetY = offsetY
        if self.stopPlay { return }
        
        var playerView: UIView?
        if self.containerType == .cell {
            guard self.contentOffset.y > 0 else { return }
            guard let playingIndexPath = self.playingIndexPath else { return }
            let cell = self.qk_getCell(at: playingIndexPath)
            if cell == nil {
                if let playerDidDisappearInScrollView = playerDidDisappearInScrollView {
                    playerDidDisappearInScrollView(playingIndexPath)
                }
                return
            }
            guard let containerViewTag = self.self.containerViewTag else { return }
            playerView = cell?.viewWithTag(containerViewTag)
        } else if self.containerType == .view {
            guard let containerView = self.containerView else { return }
            playerView = containerView
        }
        guard playerView != nil else { return }
        
        // playerVeiw 在self的坐标轴上的位置
        guard let rect1 = playerView?.convert(playerView!.frame, to: self) else { return }
        // rect 在self.superView上的位置
        let rect = self.convert(rect1, to: self.superview)
        
        let topSpacing = rect.minY - self.frame.minY - playerView!.frame.minY
        
        let bottomSpacing = self.frame.maxY - rect.maxY + playerView!.frame.minY
        
        let contentInsetHeight = self.frame.height
        
        var playerDisapperaPercent: CGFloat = 0 // 离开播放页面的百分比
        var playerApperaPercent: CGFloat = 0 // 播放页面显示的百分比
        
        if self.qk_scrollDirection == .up {
            // 计算离开当前cell页面的百分比
            if topSpacing <= 0 && rect.height != 0 {
                playerDisapperaPercent = -topSpacing / rect.height
                if playerDisapperaPercent > 1.0 { playerDisapperaPercent = 1 }
                if let playerDisapperingInScrollView = self.playerDisapperingInScrollView {
                    playerDisapperingInScrollView(playingIndexPath, playerDisapperaPercent)
                }
                
                if (topSpacing <= 0) && topSpacing > -rect.height / 2 { // 下滑开始消失时 下滑时，只要超过 playerView!.frame.minY 就是负数了
                    if let playerWillDisappearInScrollView = self.playerWillDisappearInScrollView {
                        playerWillDisappearInScrollView(playingIndexPath)
                    }
                } else if topSpacing <= -rect.height { // 完全消失
                    if let playerDidDisappearInScrollView = self.playerDidDisappearInScrollView {
                        playerDidDisappearInScrollView(playingIndexPath)
                    }
                } else if topSpacing > 0 && topSpacing <= contentInsetHeight {
                    if rect.height != 0 {
                        playerApperaPercent = -(topSpacing - contentInsetHeight) / rect.height
                        if playerApperaPercent > 1 { playerApperaPercent = 1 }
                        if let playerAppearingInScrollView = self.playerAppearingInScrollView {
                            playerAppearingInScrollView(playingIndexPath, playerApperaPercent)
                        }
                    }
                    
                    if topSpacing <= contentInsetHeight && topSpacing > contentInsetHeight - rect.height / 2 {
                        if let playerWillAppearInScrollView = self.playerWillAppearInScrollView {
                            playerWillAppearInScrollView(playingIndexPath)
                        }
                    } else {
                        if let playerDidAppearInScrollView = self.playerDidAppearInScrollView {
                            playerDidAppearInScrollView(playingIndexPath)
                        }
                    }
                }
            }
        } else if qk_scrollDirection == .bottom { // 向下滑
            
            if bottomSpacing <= 0 && rect.height != 0 {
                playerDisapperaPercent = -bottomSpacing / rect.height
                if playerDisapperaPercent > 1 { playerDisapperaPercent = 1 }
                if let playerDisapperingInScrollView = self.playerDisapperingInScrollView {
                    playerDisapperingInScrollView(playingIndexPath, playerDisapperaPercent)
                }
            }
            
            // 下区域
            if bottomSpacing <= 0 && bottomSpacing > -rect.height / 2 {
                if let playerWillDisappearInScrollView = self.playerWillDisappearInScrollView {
                    playerWillDisappearInScrollView(playingIndexPath)
                }
            } else if bottomSpacing <= -rect.height {
                if let playerDidDisappearInScrollView = self.playerDidDisappearInScrollView {
                    playerDidDisappearInScrollView(playingIndexPath)
                }
            } else if bottomSpacing > 0 && bottomSpacing <= contentInsetHeight {
                if rect.height != 0 {
                    playerApperaPercent = -(bottomSpacing - contentInsetHeight) / rect.height
                    if playerApperaPercent > 1 { playerApperaPercent = 1 }
                    if let playerAppearingInScrollView = self.playerAppearingInScrollView {
                        playerAppearingInScrollView(playingIndexPath, playerApperaPercent)
                    }
                }
                if bottomSpacing <= 0 && bottomSpacing > contentInsetHeight - rect.height / 2 {
                    if let playerWillAppearInScrollView = self.playerWillAppearInScrollView {
                        playerWillAppearInScrollView(playingIndexPath)
                    }
                } else {
                    if let playerDidAppearInScrollView = self.playerDidAppearInScrollView {
                        playerDidAppearInScrollView(playingIndexPath)
                    }
                }
            }
            
        }
    }
    
    // 横方向时 滑动进度
    func _scrollViewScrollingDirectionHorizontal() {
        let offsetX = self.contentOffset.x
        self.qk_scrollDirection = (offsetX - self.lastOffsetX > 0) ? .left : .right
        self.lastOffsetX = offsetX
        if self.stopPlay { return }
        
        var playerView: UIView?
        if self.containerType == .cell {
            if self.contentOffset.x < 0 { return }
            guard let playingIndexPath = self.playingIndexPath else { return }
            let cell = self.qk_getCell(at: playingIndexPath)
            if cell == nil {
                if let playerDidDisappearInScrollView = self.playerDidDisappearInScrollView {
                    playerDidDisappearInScrollView(playingIndexPath)
                }
                return
            }
            guard let containerViewTag = self.containerViewTag else { return }
            playerView = cell?.viewWithTag(containerViewTag)
        } else if self.containerType == .view {
            playerView = self.containerView
        }
        guard playerView != nil else { return }
        
        guard let rect1 = playerView?.convert(playerView!.frame, to: self) else { return }
        
        let rect = self.convert(rect1, to: self.superview)
        
        let leftSpacing = rect.minX - self.frame.minX - playerView!.frame.minX
        
        let rightSpacing = self.frame.maxX - rect.maxX + playerView!.frame.minX
        
        let contentInsetWidth = self.frame.width
        
        var playerDisapperaPercent: CGFloat = 0
        var playerApperaPercent: CGFloat = 0
        if self.qk_scrollDirection == .left {
            if leftSpacing <= 0 && rect.width != 0 {
                playerDisapperaPercent = -leftSpacing / rect.width
                playerDisapperaPercent = playerDisapperaPercent > 1 ? 1 : playerDisapperaPercent
                if let playerDisapperingInScrollView = self.playerDisapperingInScrollView {
                    playerDisapperingInScrollView(playingIndexPath, playerDisapperaPercent)
                }
            }
            
            if leftSpacing <= 0 && leftSpacing > -rect.width / 2 {
                if let playerWillDisappearInScrollView = self.playerWillDisappearInScrollView {
                    playerWillDisappearInScrollView(self.playingIndexPath)
                }
            } else if leftSpacing <= -rect.width {
                if let playerDidDisappearInScrollView = self.playerDidDisappearInScrollView {
                    playerDidDisappearInScrollView(playingIndexPath)
                }
            } else if leftSpacing > 0 && leftSpacing <= contentInsetWidth {
                
                if rect.width != 0 {
                    playerApperaPercent = -(leftSpacing - contentInsetWidth) / rect.width
                    playerApperaPercent = playerApperaPercent > 1 ? 1 : playerApperaPercent
                    if let playerAppearingInScrollView = self.playerAppearingInScrollView {
                        playerAppearingInScrollView(playingIndexPath, playerApperaPercent)
                    }
                }
                
                if leftSpacing <= contentInsetWidth && leftSpacing > contentInsetWidth - rect.width / 2 {
                    if let playerWillAppearInScrollView = self.playerWillAppearInScrollView {
                        playerWillAppearInScrollView(playingIndexPath)
                    }
                } else {
                    if let playerDidAppearInScrollView = self.playerDidAppearInScrollView {
                        playerDidAppearInScrollView(playingIndexPath)
                    }
                }
            }
            
        } else if self.qk_scrollDirection == .right {
            if rightSpacing <= 0 && rect.width != 0 {
                playerDisapperaPercent = rightSpacing / rect.width
                playerDisapperaPercent = playerDisapperaPercent > 1 ? 1 : playerDisapperaPercent
                if let playerDisapperingInScrollView = self.playerDisapperingInScrollView {
                    playerDisapperingInScrollView(self.playingIndexPath, playerDisapperaPercent)
                }
            }
            
            if rightSpacing <= 0 && rightSpacing > -rect.width / 2 {
                if let playerWillDisappearInScrollView = self.playerWillDisappearInScrollView {
                    playerWillDisappearInScrollView(self.playingIndexPath)
                }
            } else if rightSpacing <= -rect.width {
              
                if let playerDidDisappearInScrollView = self.playerDidDisappearInScrollView {
                    playerDidDisappearInScrollView(self.playingIndexPath)
                }
            } else if rightSpacing > 0 && rightSpacing <= contentInsetWidth {
                if rect.width != 0 {
                    playerApperaPercent = -(rightSpacing - contentInsetWidth) / rect.width
                    playerApperaPercent = playerApperaPercent > 1.0 ? 1 : playerApperaPercent
                    if let playerAppearingInScrollView = self.playerAppearingInScrollView {
                        playerAppearingInScrollView(playingIndexPath, playerApperaPercent)
                    }
                }
                
                if rightSpacing <= contentInsetWidth && rightSpacing > contentInsetWidth - rect.width / 2 {
                    if let playerWillAppearInScrollView = self.playerWillAppearInScrollView {
                        playerWillAppearInScrollView(self.playingIndexPath)
                    }
                } else { // 全部显示
                    if let playerDidAppearInScrollView = self.playerDidAppearInScrollView {
                        playerDidAppearInScrollView(playingIndexPath)
                    }
                }
            }
        }
    }
    
    // 查找滚动方向为垂直时的播放单元
    func _findCorrectCellWhenScrollViewDirectionVertical(handler: ((IndexPath)->Void)?) {
        if !self.isShouldAutoPlay { return }
        if self.containerType == .view { return }
        
        if !self.stopWhileNotVisible {
            // 如果有正在播放的播放器就不进行遍历
            if let playingIndexPath = self.playingIndexPath {
                let finalIndexPath = playingIndexPath
                if let scrollViewDidScrollCallback = self.scrollViewDidScrollCallback {
                    scrollViewDidScrollCallback(finalIndexPath)
                }
                self.shouldPlayIndexPath = finalIndexPath
                return
            }
        }
        
        
        
    }
    
    // 查找水平方向为水平时的播放单元
    func _findCorrectCellWhenScrollViewDirectionHorizontal(handler: ((IndexPath) ->Void)?) {
        
    }
    
    
    func _isTableView() ->Bool {
        return self.isKind(of: UITableView.self)
    }
    
    func _isCollectionView() ->Bool {
        return self.isKind(of: UICollectionView.self)
    }
    
    
}


extension UIScrollView {
    
    struct AssociationScrollViewStatus {
        static var playerAppearingInScrollView = "playerAppearingInScrollView"
        static var playerDisapperingInScrollView = "playerDisapperingInScrollView"
        static var playerWillAppearInScrollView = "playerWillAppearInScrollView"
        static var playerDidAppearInScrollView = "playerDidAppearInScrollView"
        static var playerWillDisappearInScrollView = "playerWillDisappearInScrollView"
        static var playerDidDisappearInScrollView = "playerDidDisappearInScrollView"
        static var scrollViewDidEndScrollingCallback = "scrollViewDidEndScrollingCallback"
        static var scrollViewDidScrollCallback = "scrollViewDidScrollCallback"
        static var playerShouldPlayInScrollView = "playerShouldPlayInScrollView"
        
        static var playerDisapperaPercent = "playerDisapperaPercent"
        static var playerApperaPercent = "playerApperaPercent"
        static var stopPlay = "stopPlay"
        static var stopWhileNotVisible = "stopWhileNotVisible"
        static var playingIndexPath = "playingIndexPath"
        static var shouldPlayIndexPath = "shouldPlayIndexPath"
        static var isWWANAutoPlay = "isWWANAutoPlay"
        static var isShouldAutoPlay = "shouldAutoPlay"
        static var containerViewTag = "containerViewTag"
        static var containerView = "containerView"
        static var containerType = "containerType"
        static var isViewControllerDisappear = "isViewControllerDisappear"
    }

    // 当播放器出现时调用
    var playerAppearingInScrollView: ((IndexPath?, CGFloat)->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.playerAppearingInScrollView) as? ((IndexPath?, CGFloat)->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.playerAppearingInScrollView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 播放器完全消失时
    var playerDisapperingInScrollView: ((IndexPath?, CGFloat)->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.playerDisapperingInScrollView) as? ((IndexPath?, CGFloat)->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.playerDisapperingInScrollView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 播放器即将出现
    var playerWillAppearInScrollView: ((IndexPath?)->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.playerWillAppearInScrollView) as? ((IndexPath?)->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.playerWillAppearInScrollView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 播放已出现
    var playerDidAppearInScrollView: ((IndexPath?)->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.playerDidAppearInScrollView) as? ((IndexPath?)->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.playerDidAppearInScrollView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    // 播放器即将消失
    var playerWillDisappearInScrollView: ((IndexPath?)->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.playerWillDisappearInScrollView) as? ((IndexPath?)->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.playerWillDisappearInScrollView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 播放器已消失
    var playerDidDisappearInScrollView: ((IndexPath?)->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.playerDidDisappearInScrollView) as? ((IndexPath?)->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.playerDidDisappearInScrollView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 滑动中回调
    var scrollViewDidEndScrollingCallback: ((IndexPath?)->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.scrollViewDidEndScrollingCallback) as? ((IndexPath?)->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.scrollViewDidEndScrollingCallback, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 滑动结束回调
    var scrollViewDidScrollCallback: ((IndexPath?)->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.scrollViewDidScrollCallback) as? ((IndexPath?)->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.scrollViewDidScrollCallback, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 即将播放的索引回调
    var playerShouldPlayInScrollView: ((IndexPath)->Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.playerShouldPlayInScrollView) as? ((IndexPath?)->Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.playerShouldPlayInScrollView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 播放器消失百分比
    var playerDisapperaPercent: CGFloat? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.playerDisapperaPercent) as? CGFloat
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.playerDisapperaPercent, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 播放器显示百分比
    var playerApperaPercent: CGFloat? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.playerApperaPercent) as? CGFloat
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.playerApperaPercent, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 停止播放
    var stopPlay: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.stopPlay) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.stopPlay, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 播放器离开屏幕时停止播放，默认为true
    var stopWhileNotVisible: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.stopWhileNotVisible) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.stopWhileNotVisible, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 播放中的索引
    var playingIndexPath: IndexPath? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.playingIndexPath) as? IndexPath
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.playingIndexPath, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let playingIndexPath = newValue, let shouldPlayIndexPath = shouldPlayIndexPath, playingIndexPath.compare(shouldPlayIndexPath) != .orderedSame {
                self.shouldPlayIndexPath = playingIndexPath
            }
        }
    }
    
    // 即将播放的索引
    var shouldPlayIndexPath: IndexPath? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.shouldPlayIndexPath) as? IndexPath
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.shouldPlayIndexPath, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let playerShouldPlayInScrollView = playerShouldPlayInScrollView, let indexPath = newValue {
                playerShouldPlayInScrollView(indexPath)
            }
        }
    }
    
    // 移动网络是是否自动播放，默认false
    var isWWANAutoPlay: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.isWWANAutoPlay) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.isWWANAutoPlay, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 是否自动播放
    var isShouldAutoPlay: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.isShouldAutoPlay) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.isShouldAutoPlay, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 容器tag
    var containerViewTag: Int? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.containerViewTag) as? Int
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.containerViewTag, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 容器
    var containerView: UIView? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.containerView) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.containerView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 播放器容器类型
    var containerType: QKPlayerContainerType {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.containerType) as? QKPlayerContainerType ?? .view
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.containerType, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 记录控制器显示状态
    var isViewControllerDisappear: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociationScrollViewStatus.isViewControllerDisappear) as? Bool
        }
        set {
            objc_setAssociatedObject(self, &AssociationScrollViewStatus.isViewControllerDisappear, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
     
    func filterShouldPlayCellWhileScrolling(handler: ((IndexPath)->Void)?) {
        if self.qk_scrollViewDirection == .vertical {
            _findCorrectCellWhenScrollViewDirectionVertical(handler: handler)
        } else {
            _findCorrectCellWhenScrollViewDirectionHorizontal(handler: handler)
        }
    }
    
    // 过滤即将播放的索引
    func filterShouldPlayCellWhileScrolled(handler: @escaping ((IndexPath)->Void)) {
        guard self.isShouldAutoPlay else { return }
        self.filterShouldPlayCellWhileScrolling { [weak self](indexPath) in
            guard let `self` = self else { return }
            guard let isViewControllerDisappear = self.isViewControllerDisappear, isViewControllerDisappear == false else { return }
            handler(indexPath)
            self.playingIndexPath = indexPath
        }
    }
}

