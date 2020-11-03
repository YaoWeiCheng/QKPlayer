//
//  QKUtils.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/10.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

class QKUtils: NSObject {

    static func converTimeSecond(timeSecond: Int) -> String {
        var theLastTime: String = "00:00"
        let second = timeSecond
        if timeSecond < 60 {
            theLastTime = String(format: "00:%02zd", second)
        } else if timeSecond >= 60 && timeSecond < 3600 {
            theLastTime = String(format: "%02zd:%02zd", second/60, second%60)
        } else if timeSecond > 3600 {
            theLastTime = String(format: "%02zd:%02zd:%02zd", second / 3600, second % 3600 / 60, second % 60)
        }
        return theLastTime
    }
    
    static func imageName(name: String) ->UIImage? {
        guard let path = Bundle.main.path(forResource: "QKPlayer", ofType: "bundle") else { return nil }
        let url = path + "/" + name
        let image = UIImage(contentsOfFile: url)
        return image
    }
}

