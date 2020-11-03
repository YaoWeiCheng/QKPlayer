//
//  ViewController.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/6.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

class ViewController: UIViewController {


    let normalPlayBtn = UIButton()
    let collectionBtn = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        self.view.addSubview(normalPlayBtn)
        normalPlayBtn.frame = CGRect(x: 40, y: 100, width: 100, height: 50)
        normalPlayBtn.setTitle("普通播放", for: .normal)
        normalPlayBtn.addTarget(self, action: #selector(playClickAction), for: .touchUpInside)
        normalPlayBtn.backgroundColor = .systemBlue

        self.view.addSubview(collectionBtn)
        collectionBtn.frame = CGRect(x: 40, y: 300, width: 100, height: 50)
        collectionBtn.setTitle("列表播放", for: .normal)
        collectionBtn.addTarget(self, action: #selector(collectionPlayClickAction), for: .touchUpInside)
        collectionBtn.backgroundColor = .systemRed
    }

    @objc func playClickAction() {
        let vc = QKNormalViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc func collectionPlayClickAction() {
        let vc = QKCollectionViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    deinit {
        print("\(self) deinit")
    }
}

