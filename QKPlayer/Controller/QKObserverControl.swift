//
//  QKObserverControl.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/6.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

class QKKVOEntry: NSObject {
    
    weak var observer: NSObject?
    
    var keyPath: String?
}

class QKObserverControl: NSObject {

    weak var target: NSObject?
    // 观察者数组
    var observersArray = [QKKVOEntry]()
    
    required init(target: NSObject) {
        super.init()
        self.target = target
    }
    
    // MARK: - 添加监听
    public func qkAddObserver(_ observer: NSObject, forKeyPath keyPath: String, options: NSKeyValueObservingOptions = [], context: UnsafeMutableRawPointer?) {
        
        guard let _target = self.target else { return }
        
        // 先移除，如果有的话
        self.removeEntryOfObserver(observer: observer, keyPath: keyPath)
        
        _target.addObserver(observer, forKeyPath: keyPath, options: options, context: context)
        
        let entry = QKKVOEntry()
        entry.observer = observer
        entry.keyPath  = keyPath
        self.observersArray.append(entry) // 通过数组保存引用
        
    }
    
    // MARK: - 删除单个监听
    public func qkRemoveObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        
        guard let _target = self.target else { return }
        // 移除
        let removed = removeEntryOfObserver(observer: observer, keyPath: keyPath)
        if removed {
            _target.removeObserver(observer, forKeyPath: keyPath)
        }
    }
    
    // MARK: - 删除所有监听
    public func qkRemoveAllObservers() {
        guard let _target = self.target else { return }
        for (_, item) in self.observersArray.enumerated() {
            guard let observer = item.observer else { break }
            guard let keyPath = item.keyPath else { break }
            _target.removeObserver(observer, forKeyPath: keyPath)
        }
        self.observersArray.removeAll()
    }
    
    // MARK: - 删除单个target数据
    @discardableResult
    private func removeEntryOfObserver(observer: NSObject, keyPath: String) ->Bool {
                
        for (idx, item) in self.observersArray.enumerated() {
            if item.observer == observer && item.keyPath == keyPath {
                self.observersArray.remove(at: idx)
                return true
            }
        }
        return false
    }
    
}
