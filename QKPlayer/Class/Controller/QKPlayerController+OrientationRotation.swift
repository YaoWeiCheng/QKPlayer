//
//  QKPlayerController+OrientationRotation.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/14.
//  Copyright © 2020 cyw. All rights reserved.
//

import Foundation


extension QKPlayerController {
    
    struct AssociationOrientationRotation {
        static var orientationObserver = "orientationObserver"
    }
    
    public var orientationObserver: QKOrientationObserver? {
        get {
            var orientationObserver: QKOrientationObserver? = objc_getAssociatedObject(self, &AssociationOrientationRotation.orientationObserver) as? QKOrientationObserver
            if orientationObserver == nil {
                orientationObserver = QKOrientationObserver()
                orientationObserver?.orientationWillChange = { [weak self](observer, ifFullScreen) in
                    guard let `self` = self else { return }
                    self.controlView?.videoPlayer(playerControl: self, orientationWillChange: observer)
                    self.controlView?.setNeedsLayout()
                    self.controlView?.layoutIfNeeded()
                }
                orientationObserver?.orientationDidChanged = { [weak self](observer, ifFullScreen) in
                    guard let `self` = self else { return }
                    self.controlView?.videoPlayer(playerControl: self, orientationDidChanged: observer)
                }
                objc_setAssociatedObject(self, &AssociationOrientationRotation.orientationObserver, orientationObserver, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return orientationObserver
        }
        
        set {
            objc_setAssociatedObject(self, &AssociationOrientationRotation.orientationObserver, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var isFullScreen: Bool {
        get {
            return self.orientationObserver?.isFullScreen ?? false
        }
    }
//    public var orientationWillChange: (QKOrientationObserver)
    
    
    // MARK: - Public Method
    
    // 竖屏、全屏模式切换
    public func enterPortrait(fullScreen: Bool, animated: Bool) {
        self.orientationObserver?.fullScreenMode = .portrait
        self.orientationObserver?.enterPortrait(fullScreen: fullScreen, animated: animated)
    }
    
}
