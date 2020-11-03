//
//  QKPlayer.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/7.
//  Copyright © 2020 cyw. All rights reserved.
//

import Foundation
@_exported import AVFoundation
@_exported import UIKit

/**
 机型的屏幕大小
 */
let QKPlayer_Device_Is_PHONE = __CGSizeEqualToSize(CGSize.init(width: 750/2, height: 1334/2), UIScreen.main.bounds.size)
let QKPlayer_Device_Is_PHONEPlus = __CGSizeEqualToSize(CGSize.init(width: 1242/3, height: 2208/3), UIScreen.main.bounds.size)
let QKPlayer_Device_Is_iPhoneX=__CGSizeEqualToSize(CGSize.init(width: 1125/3, height: 2436/3), UIScreen.main.bounds.size)
let QKPlayer_Device_Is_iPhoneXr=__CGSizeEqualToSize(CGSize.init(width: 828/2, height: 1792/2), UIScreen.main.bounds.size)
let QKPlayer_Device_Is_iPhoneXs=__CGSizeEqualToSize(CGSize.init(width: 1125/3, height: 2436/3), UIScreen.main.bounds.size)
let QKPlayer_Device_Is_iPhoneXs_Max=__CGSizeEqualToSize(CGSize.init(width: 1242/3, height: 2688/3), UIScreen.main.bounds.size)
let QKPlayer_IsIphoneX = (QKPlayer_Device_Is_iPhoneX || QKPlayer_Device_Is_iPhoneXr || QKPlayer_Device_Is_iPhoneXs||QKPlayer_Device_Is_iPhoneXs_Max)

// 屏幕宽度
let QKPlayer_ScreenWidth:CGFloat = UIScreen.main.bounds.width
// 屏幕高度
let QKPlayer_ScreenHeight:CGFloat = UIScreen.main.bounds.height
/**安全区域顶部高度*/
let QKPlayer_SafeAreaTopHeight:CGFloat = (QKPlayer_ScreenHeight >= 812.0) ? 88 : 64
/**安全区域底部高度*/
let QKPlayer_SafeAreaBottomHeight:CGFloat = (QKPlayer_ScreenHeight >= 812.0) ? 34 : 0
