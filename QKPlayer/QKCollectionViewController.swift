//
//  QKCollectionViewController.swift
//  QKPlayer
//
//  Created by 程耀威 on 2020/8/18.
//  Copyright © 2020 cyw. All rights reserved.
//

import UIKit

class QKCollectionViewController: UIViewController {

    let identify = "QKListCollectionViewCell"
    var collectionView: UICollectionView?
    
    var playerController: QKPlayerController?
    var controllerView: QKListPlayerController = QKListPlayerController()

    let urlsArray: [URL] = [
        URL(string: "https://www.apple.com/105/media/us/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-tpl-cc-us-20170912_1280x720h.mp4")!,URL(string: "https://www.apple.com/105/media/us/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-tpl-cc-us-20170912_1280x720h.mp4")!,
    ]
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        createPlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.playerController?.isViewControllerDisappear = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.playerController?.isViewControllerDisappear = true
        
        
    }
    

    deinit {
         print("\(self) deinit")
     }
    
    
    // MARK: - 创建UI
    func setupUI() {
    
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: QKPlayer_ScreenWidth, height: QKPlayer_ScreenHeight)
        layout.scrollDirection = .horizontal
        
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
        self.collectionView?.isPagingEnabled = true
        self.collectionView?.qk_scrollViewDirection = .horizontal
        self.view.addSubview(self.collectionView!)
        self.collectionView?.register(QKListCollectionViewCell.self, forCellWithReuseIdentifier: identify)
    }
    
    func createPlayer() {
        let playerManager = QKAVPlayerManager()

        self.playerController = QKPlayerController(scrollView: self.collectionView!, playerManager: playerManager, containerViewTag: 100)
        self.playerController?.controlView = self.controllerView
        self.playerController?.assetURLs = urlsArray
        self.playerController?.playerDisapperaPercent = 1.0
        self.playerController?.pauseWhenAppResignActive = true
        
        self.controllerView.autoHiddenTimeInterval = 5
        self.controllerView.autoFadeTimeInterval = 0.5
        self.controllerView.prepareShowLoading = true
        self.controllerView.prepareShowControlView = true
        self.collectionView?.reloadData()
        controllerView.showControlView()
    }
    
    func playTheVideoAtIndexPath(indexPath: IndexPath) {
        
        self.playerController?.playTheIndexPath(indexPath: indexPath)
        self.controllerView.resetControlView()
        
    }
    
}


extension QKCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return urlsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: QKListCollectionViewCell! = collectionView.dequeueReusableCell(withReuseIdentifier: identify, for: indexPath) as? QKListCollectionViewCell
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.playTheVideoAtIndexPath(indexPath: indexPath)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollView.qk_scrollViewDidEndDecelerating()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollView.qk_scrollViewDidEndDecelerating()
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollView.qk_scrollViewDidScrollToTop()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.qk_scrollViewDidScroll()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.qk_scrollViewWillBeginDragging()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat.zero
    }
}
