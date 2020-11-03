//
//  QKPlayerNotification.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/20.
//  Copyright © 2020 cyw. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

enum QKPlayerBackgroundState {
    case foreground
    case background
}

class QKPlayerNotification: NSObject {
    
    // MARK: - Public Property
    
    public var backgroundState = QKPlayerBackgroundState.foreground
    // 进入后台回调
    public var willResignActiveCallback: ((QKPlayerNotification)->Void)?
    // 进入前台回调
    public var didBecomeActiveCallback: ((QKPlayerNotification)->Void)?
    // 比如有耳机插入时回调
    public var newDeviceAvailable: ((QKPlayerNotification)->Void)?
    // 比如耳机拔出时回调
    public var oldDeviceUnavailable: ((QKPlayerNotification)->Void)?
    // 类别改变时回调
    public var categoryChangeCallback: ((QKPlayerNotification)->Void)?
    // 音量回调
    public var volumeDidChange: ((CGFloat)->Void)?
    // 中断类型回调
    public var interruptionCallback: ((AVAudioSession.InterruptionType)->Void)?
    
    
    // MARK: - Public Method
    
    public func addNotification() {
        // 多用于监听(AVAudioSessionRouteChangeNotification)耳机等设备变化之后，是否暂停播放音频。
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionRouteChangeNotification), name: AVAudioSession.routeChangeNotification, object: nil)
        // 进入后台的注册监听
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)
        // 是否进入前台的监听
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
        // 音量的监听
        NotificationCenter.default.addObserver(self, selector: #selector(volumeDidChangeNotification), name: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        // 表示中断类型，用于判断中断开始或者结束。用AVAudioSessionInterruptionNotification进行通知。
        NotificationCenter.default.addObserver(self, selector: #selector(interruptionNotification), name: AVAudioSession.interruptionNotification, object: nil)
        
    }
    
    public func removeNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Action
    
    // 多用于监听(AVAudioSessionRouteChangeNotification)耳机等设备变化之后，是否暂停播放音频。 监听回调
    @objc func audioSessionRouteChangeNotification(notice: NSNotification) {
        
        DispatchQueue.main.async {
            let userInfo = notice.userInfo
            let routeChengeReason = userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            switch routeChengeReason {
            case AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue: // 比如耳机插入
                if let newDeviceAvailable = self.newDeviceAvailable {
                    newDeviceAvailable(self)
                }
            case AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue: // 比如耳机拔出
                if let oldDeviceUnavailable = self.oldDeviceUnavailable {
                    oldDeviceUnavailable(self)
                }
            case AVAudioSession.RouteChangeReason.categoryChange.rawValue: // 比如类别变化，AVAudioSessionCategoryPlayback改成AVAudioSessionCategoryPlayAndRecord
                if let categoryChangeCallback = self.categoryChangeCallback {
                    categoryChangeCallback(self)
                }
            default: break
            }
        }
    }
    
    // 进入后台的注册监听 回调
    @objc func willResignActiveNotification(notice: NSNotification) {
        self.backgroundState = .background
        if let willResignActiveCallback = self.willResignActiveCallback {
            willResignActiveCallback(self)
        }
    }
    
    // 是否进入前台的监听回调
    @objc func didBecomeActiveNotification(notice: NSNotification) {
        self.backgroundState = .foreground
        if let didBecomeActiveCallback = self.didBecomeActiveCallback {
            didBecomeActiveCallback(self)
        }
    }
    
    // 音量的监听 回调
    @objc func volumeDidChangeNotification(notice: NSNotification) {
        let userInfo = notice.userInfo
        let volume = userInfo?["AVSystemController_AudioVolumeNotificationParameter"] as? CGFloat
        if let olumeDidChange = self.volumeDidChange, let volume = volume {
            olumeDidChange(volume)
        }
    }
    
    // 表示中断类型，用于判断中断开始或者结束。用AVAudioSessionInterruptionNotification进行通知。 监听回调
    // AVAudioSession.InterruptionType case began = 1  case ended = 0
    @objc func interruptionNotification(notice: NSNotification) {
        let userInfo = notice.userInfo
        guard let interruptionType = userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
        if let interruptionCallback = self.interruptionCallback, let type = AVAudioSession.InterruptionType(rawValue: interruptionType) {
            interruptionCallback(type)
        }
    }
}
