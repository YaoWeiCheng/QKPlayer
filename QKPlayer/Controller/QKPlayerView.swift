//
//  QKPlayerView.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/6.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

class QKPlayerView: UIView {

    weak var fitView: UIView?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        if self.isUserInteractionEnabled == false || self.isHidden == true || self.alpha <= 0.01 { return nil }
        
        if !self.point(inside: point, with: event) { return nil }
        
        let count = self.subviews.count
        for i in (0..<count).reversed() { // 从最高的view开始查找
            let childView = self.subviews[i]
            let childPoint = self.convert(point, to: childView)
            let fitView = childView.hitTest(childPoint, with: event)
            if fitView != nil {
                return fitView
            }
        }
        return self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { }
}
