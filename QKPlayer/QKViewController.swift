//
//  QKViewController.swift
//  QKPlayer
//
//  Created by CYW on 2020/8/19.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

class QKViewController: UIViewController {

//    let playerManager = QKAVPlayerManager()
    let controllView = QKPlayerControlView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
        controllView.frame = CGRect(x: 0, y: 0, width: QKPlayer_ScreenWidth, height: QKPlayer_ScreenHeight)
        self.view.addSubview(controllView)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
//        playerManager.assetURL = URL(string: "https://www.apple.com/105/media/us/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-tpl-cc-us-20170912_1280x720h.mp4")
        controllView.showControlView(animate: true)
    }
    
    deinit {
        print("\(self) deinit")
    }


}
