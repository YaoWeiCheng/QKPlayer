# QKPlayer

#### 介绍
iOS播放器

纯Swift 开发，可自定义UI、tableView与CollectionView 播放


### 用法：

普通用法：


    class QKNormalViewController: UIViewController {

        var playerController: QKPlayerController?
        var controllerView: QKPlayerControlView = QKPlayerControlView()
        var containerView: UIImageView = UIImageView()
        let playBtn = UIButton()


        override func viewDidLoad() {
            super.viewDidLoad()


            // Do any additional setup after loading the view.
            self.view.backgroundColor = .white
            self.view.addSubview(self.containerView)
            self.containerView.frame = CGRect(x: 0, y: QKPlayer_SafeAreaTopHeight, width: QKPlayer_ScreenWidth, height: 300)
            self.containerView.backgroundColor = .black
            containerView.isUserInteractionEnabled = true

            let size: CGFloat = 40
            let x = (QKPlayer_ScreenWidth - size) / 2
            let y = (containerView.frame.height - size) / 2
            self.containerView.addSubview(self.playBtn)
            self.playBtn.frame = CGRect(x: x, y: y, width: 40, height: 40)
            self.playBtn.setImage(UIImage(named: "icon_big_play"), for: .normal)
            self.playBtn.addTarget(self, action: #selector(playClickAction), for: .touchUpInside)

            let playerManager = QKAVPlayerManager()

            playerController = QKPlayerController(playerManager: playerManager, containerView: self.containerView)
            playerController?.controlView = self.controllerView
            self.controllerView.prepareShowLoading = true
            self.controllerView.prepareShowControlView = true
            controllerView.autoHiddenTimeInterval = 5;
            controllerView.autoFadeTimeInterval = 0.25;
            self.controllerView.showFullScreenModel(fullScreenModel: .portrait)
            playerController?.playerDidToEnd = { [weak self](asset) in
                guard let `self` = self else { return }
                self.playerController?.stop()
            }
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            self.playerController?.isViewControllerDisappear = false
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            self.playerController?.isViewControllerDisappear = true
        }



        @objc func playClickAction() {

            playerController?.assetURL = URL(string: "https://www.apple.com/105/media/us/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-tpl-cc-us-20170912_1280x720h.mp4")

        }

        deinit {
             print("\(self) deinit")
         }
    }

其他用法可以下载源码查看。


