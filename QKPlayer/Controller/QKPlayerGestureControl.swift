//
//  QKPlayerGestureControl.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/12.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

// 手势类型
enum QKPlayerGestureType {
    case unknown
    case sigleTap
    case doubleTap
    case pan
    case pinch
}

// 拖动方向
enum QKPlayerPanDirection {
    case unknown
    case vertival   // 竖
    case horizontal // 横
}

// 拖动位置
enum QKPlayerPanLocation {
    case unknown
    case left
    case right
}

// 拖动类型
enum QKPlayerMovingDirection {
    case unknown
    case top
    case left
    case right
    case bottom
}

// 禁止点击的手势类型
enum QKPlayerDisableGestureTypes: Int {
    case none           = 0
    case sigleTap       = 1
    case doubleTap      = 2
    case pan            = 3
    case pinch          = 4
    case all            = 5
}

// 禁止拖动的手势
enum QKPlayerDisablePanMovingDirection: Int {
    case none           = 0
    case vertival       = 1
    case horizontal     = 2
    case all            = 3
}


class QKPlayerGestureControl: NSObject {

    // 单点
    lazy var singleTap: UITapGestureRecognizer = {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.delegate = self
        singleTap.delaysTouchesBegan = true
        singleTap.delaysTouchesEnded = true
        singleTap.numberOfTouchesRequired = 1
        singleTap.numberOfTapsRequired = 1
        return singleTap
    }()
    
    
    // 双击
    lazy var doubleTap: UITapGestureRecognizer = {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(hnadleDoubleTap))
        doubleTap.delegate = self
        doubleTap.delaysTouchesBegan = true
        doubleTap.delaysTouchesEnded = true
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.numberOfTapsRequired = 2
        return doubleTap
    }()
    
    weak var targetView: UIView?
    // 单击回调
    public var singleTapedCallback: ((QKPlayerGestureControl)->Void)?
    // 双击回调
    public var doubleTapedCallback: ((QKPlayerGestureControl)->Void)?
    
    deinit {
//        print("\(self) deint")
    }
    
    // MARK: - Public method
    
    // MARK: - 添加手势
    public func addGestureToView(targetView: UIView) {
        self.targetView = targetView
        targetView.isMultipleTouchEnabled = true
        singleTap.require(toFail: self.doubleTap)
        targetView.addGestureRecognizer(self.singleTap)
        targetView.addGestureRecognizer(self.doubleTap)
    }
    
    // MARK: - 移除手势
    public func removeGestureToView(targetView: UIView) {
        targetView.removeGestureRecognizer(self.singleTap)
        targetView.removeGestureRecognizer(self.doubleTap)
    }
    
    // MARK: - Action
    
    // MARK: - 单击
    @objc func handleSingleTap(single: UITapGestureRecognizer) {
        if let singleTapedCallback = self.singleTapedCallback {
            singleTapedCallback(self)
        }
    }
    
    // MARK: - 双击
    @objc func hnadleDoubleTap(double: UITapGestureRecognizer) {
        if let doubleTapedCallback = doubleTapedCallback {
            doubleTapedCallback(self)
        }
    }
}

extension QKPlayerGestureControl: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer != self.singleTap ||
            otherGestureRecognizer != self.doubleTap {
            return false
        }
        return true
    }
}
