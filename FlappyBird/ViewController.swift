//
//  ViewController.swift
//  FlappyBird
//
//  Created by 藤田恵梨子 on 2020/07/19.
//  Copyright © 2020 eriko.fujita. All rights reserved.
//

import UIKit
import SpriteKit


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // SKViewに型を変換する
        let skView = self.view as! SKView
        
        // FPSを表示する
        skView.showsFPS = true
        
        
        // ノードの数を表示
        skView.showsNodeCount = true
        
        // ビューと同じサイズでシーンを作成する
        let scene = GameScene(size: skView.frame.size)
        
        
        // ビューにシーンを表示する
        skView.presentScene(scene)
    }
    
    
    // ステータスバーを消す
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }


}

