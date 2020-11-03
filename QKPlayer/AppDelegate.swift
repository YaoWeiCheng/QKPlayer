//
//  AppDelegate.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/6.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//        exceptionLogWithData()
        return true
    }


    func exceptionLogWithData() {
//        CDUncaughtExceptionHandle.shared.setDefaultHandler()
        
        setDefaultHandler()
        
        let str = getdataPath()
        let data = NSData.init(contentsOfFile: str)
        if data != nil {
            let crushStr = String.init(data: data! as Data, encoding: String.Encoding.utf8)
            print(crushStr!)
        }
    }
    
    public func getdataPath() -> String{
        let str = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
        let urlPath = str.appending("Exception.txt")
        return urlPath
    }
    
    public func setDefaultHandler() {
        NSSetUncaughtExceptionHandler { (exception) in
            let arr:NSArray = exception.callStackSymbols as NSArray
            let reason:String = exception.reason!
            let name:String = exception.name.rawValue
            let date:NSDate = NSDate()
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "YYYY/MM/dd hh:mm:ss SS"
            let strNowTime = timeFormatter.string(from: date as Date) as String
            let url:String = String.init(format: "========异常错误报告========\ntime:%@\nname:%@\nreason:\n%@\ncallStackSymbols:\n%@",strNowTime,name,reason,arr.componentsJoined(by: "\n"))
            let documentpath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
            let path = documentpath.appending("Exception.txt")
            print(url)
            do{
//                try url.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            }catch let e {
                print(e.localizedDescription)
            }
        }
      }
}

