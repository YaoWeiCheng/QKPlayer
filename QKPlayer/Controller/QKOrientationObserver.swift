//
//  QKOrientationObserver.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/11.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

enum QKFullScreenMode {
    case automatic
    case landscape
    case portrait
}

enum QKRotateType {
    case normal
    case cell
    case cellOther
}


class QKOrientationObserver: NSObject {

    // 全屏view
    public lazy var fullScreenContainerView: UIView? = {
        let fullScreenContainerView = UIApplication.shared.keyWindow
        return fullScreenContainerView
    }()
    // 容器
    public weak var containerView: UIView?
    // 全屏标示
    public var isFullScreen = false
    // 满屏状态
    public var fullScreenMode = QKFullScreenMode.landscape
    // 动画时间
    public var duration: TimeInterval = 0.25
    // 即将更改模式
    public var orientationWillChange: ((QKOrientationObserver, Bool) ->Void)?
    // 更改模式完毕
    public var orientationDidChanged: ((QKOrientationObserver, Bool) ->Void)?
    // 全屏view
    private lazy var customWindow: UIWindow = createCustomWindow()
    
    private lazy var blackView: UIView = {
       let blackView = UIView()
        blackView.backgroundColor = .black
        return blackView
    }()
    // Player
    private weak var view: QKPlayerView?
    
    private var roateType = QKRotateType.normal
    
    private weak var cell: UIView?
    
    private var playerViewTag: Int?
    
    // MARK: - Private method
    
    // 创建自定义窗口
    private func createCustomWindow() -> UIWindow {
        var window: UIWindow = UIWindow(frame: .zero)
        if #available(iOS 13.0, *) {
            var windowScene: UIWindowScene?
            for scene in UIApplication.shared.connectedScenes {
                if scene.activationState == .foregroundActive {
                    windowScene = scene as? UIWindowScene
                }
                if (windowScene == nil) && UIApplication.shared.connectedScenes.count == 1 {
                    windowScene = scene as? UIWindowScene
                }
            }
            if let windowScene = windowScene {
                window = UIWindow(windowScene: windowScene)
            } else {
                window = UIWindow(frame: .zero)
            }
        } else {
            window = UIWindow(frame: .zero)
        }
        return window
    }
    
    // MARK: - Public method
    
    public func updateRotateView(rotateView: QKPlayerView, containerView: UIView) {
        self.roateType = .normal
        self.view = rotateView
        self.containerView = containerView
    }
    
    public func updateRotateView(rotateView: QKPlayerView, cell: UIView, playerViewTag: Int) {
        self.roateType = .cell
        self.view = rotateView
        self.cell = cell
        self.playerViewTag = playerViewTag
    }
    
    // MARK: - 竖屏的全屏设置
    public func enterPortrait(fullScreen: Bool, animated: Bool) {
        guard self.fullScreenMode == .portrait, let view = self.view  else { return }
        var superView: UIView?
        if fullScreen {
            guard let fullScreenContainerView = self.fullScreenContainerView else { return }
            superView = fullScreenContainerView
            self.view?.frame = self.view?.convert(view.frame, to: superView) ?? .zero
            superView?.addSubview(view)
            self.isFullScreen = true
        } else {
            if roateType == .cell, let playerViewTag = self.playerViewTag {
                superView = self.cell?.viewWithTag(playerViewTag)
            } else {
                superView = self.containerView
            }
            self.isFullScreen = false
        }
        if let orientationWillChange = self.orientationWillChange { orientationWillChange(self, self.isFullScreen)}
        let frame: CGRect = superView?.convert(superView?.frame ?? .zero, to: self.fullScreenContainerView) ?? .zero
        if animated {
            UIView.animate(withDuration: duration, animations: {
                view.frame = frame
                view.layoutIfNeeded()
            }) { (finished) in
                superView?.addSubview(view)
                view.frame = superView?.bounds ?? .zero
                if let orientationDidChanged = self.orientationDidChanged { orientationDidChanged(self, self.isFullScreen)}
            }
        } else {
            superView?.addSubview(view)
            self.view?.frame = superView?.bounds ?? .zero
            self.view?.layoutIfNeeded()
            if let orientationDidChanged = self.orientationDidChanged { orientationDidChanged(self, self.isFullScreen)}
        }
        
    }

    
}
