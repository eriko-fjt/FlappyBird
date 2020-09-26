

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    
    var scrollNode: SKNode!
    var wallNode: SKNode!
    var bird: SKSpriteNode!
    var itemNode: SKNode! // 課題
    var heartNode: SKNode! // 課題
    
    // 衝突判定カテゴリー (7.4で追加）
    let birdCategory: UInt32 = 1 << 0     // 0...000001
    let groundCategory: UInt32 = 1 << 1   // 0...000010
    let wallCategory: UInt32 = 1 << 2     // 0...000100
    let scoreCategory: UInt32 = 1 << 3    // 0...001000
    let itemCategory: UInt32 = 1 << 4     // 0...010000  // 課題用
    let heartCategory: UInt32 = 1 << 5    // 0...100000  // 課題用
    let deadlineCategory: UInt32 = 1 << 6 // 画面外に出てしまった判定用
    
    
    // スコア用変数　(7.4で追加）
    var score = 0
    
    // 8.2で追加　スコア・ベストスコア表示用
    var scoreLabelNode: SKLabelNode!
    var bestScoreLabelNode: SKLabelNode!
    
    // 課題用
    var itemScore = 0
    var itemScoreLabelNode: SKLabelNode!
    
    var heartPoint = 1
    var heartPointLabelNode: SKLabelNode!    // ハートの　❤️ x 数字を表示する部分
    
    // 8.1で追加  ベストスコアをUserDefaultsで保存するために、UserDefaults.standardプロパティで、UserDefaultsを取得
    // 課題のitemScoreのベストスコアを保存するかは未定。保存するのであれば、キーを変えてここに保存するのでitemScore用に新たに登録はしない。
    let userDefaults: UserDefaults = UserDefaults.standard
    
    // ゲームオーバー表示用
    var gameOverLabelNode:SKLabelNode!
    
    
    // 課題　BGM、効果音を登録　　効果音は、クレジット不要のフリー素材。今回のBGMは、著作権表示が必要な素材を使用
    // 各効果音のPathは、関数を作成し、その中で取得した。
    var itemGetPlayer: AVAudioPlayer!
    var heartGetPlayer: AVAudioPlayer!
    var crashPlayer: AVAudioPlayer!
    //var downOnGroundPlayer: AVAudioPlayer!  // 地面との衝突判定が個別に必要になるので、コードを書くのに少々手間がかかるのでやめる。
    
    //BGM用のノード
    var bgmNode = SKAudioNode()    // BGMは、SKAudioNode()で実装

    
    // BGMのクレジット表示のためのラベル
    // BGM素材は、「フリーBGM・音楽素材MusMus http://musmus.main.jp/」より使わせていただきました
    var bgmCreditLabelNode: SKLabelNode!   // BGM再生中は、”BGM:MusMus”を表示する。このアプリは一般公開向けではないが、念のため、著作権表示規約がある音楽は画面に表示する
    
    
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        //　重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        // 背景色
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // 課題用のアイテム用ノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        // 課題　ハートのノード
        heartNode = SKNode()
        scrollNode.addChild(heartNode)
        
        
        //BGM
        bgmNode = SKAudioNode(fileNamed: "bgm2.mp3")
        addChild(bgmNode)
        
        
        // メソッドに分割した各種スプライトを生成する処理を実行する
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        
        setupItem()
        setupHeart()
        setupDeadline()
        setupSoundPlayer()
        setupCreditLabel()
        
        setupScoreLabel()
        setupGameOverLabel()
        gameOverLabelNode.isHidden = true
    }
    
    // 課題　数が多くなったので、didMoveの中とは別に、各効果音用のプレイヤーに音源をセットする関数を作る
    func setupSoundPlayer() {
        
        let itemGetPath = Bundle.main.bundleURL.appendingPathComponent("itemGet1.mp3")
        let heartGetPath = Bundle.main.bundleURL.appendingPathComponent("heartGet.mp3")
        let crashPath = Bundle.main.bundleURL.appendingPathComponent("crashSound.mp3")
        
        // 各効果音用のプレイヤーに、音源をセットする
        // アイテム取得音をセット
        do {
            itemGetPlayer = try AVAudioPlayer(contentsOf: itemGetPath)
        } catch {
            print("アイテム音、取得エラー")
        }
        
        // ハート取得音をセット
        do {
            heartGetPlayer = try AVAudioPlayer(contentsOf: heartGetPath)
        } catch {
            print("ハート音、取得エラー")
        }
        
        // クラッシュ音をセット
        do {
            crashPlayer = try AVAudioPlayer(contentsOf: crashPath)
        } catch {
            print("クラッシュ音、取得エラー")
        }
        
    }
    
    // 地面の設定
    func setupGround() {
        // 地面の色を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール -> 元の位置　-> 左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // ground のスプライトを設置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            // スプライトにアクションを設定
            sprite.run(repeatScrollGround)
            
            // スプライトに物理演算を設定 　（7.2で追加）
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 7.4で追加　衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            // 衝突時に動かないように設定 　(7.2で追加）
            sprite.physicsBody?.isDynamic = false
            
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
            
            // テスクチャを指定してスプライトを指定する
            let groundSprite = SKSpriteNode(texture: groundTexture)
            
            
            // スプライトの表示する位置を指定する
            groundSprite.position = CGPoint(
                x: groundTexture.size().width / 2,
                y: groundTexture.size().height / 2
            )
            
            // シーンにスプライトを追加する
            addChild(groundSprite)
        }
    }
    
    // 雲の生成・設定
    func setupCloud() {
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        
        for i in 0..<needCloudNumber {
            
            let sprite = SKSpriteNode(texture: cloudTexture)
            
            sprite.zPosition = -100
            

            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            sprite.run(repeatScrollCloud)
            
            
            scrollNode.addChild(sprite)
        }
    }
    
    
    // 壁の生成・設定
    func setupWall() {
        
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        // 自身を取り除くアクション
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクション
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 鳥のサイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        
        // 鳥が通り抜ける隙間の長さを鳥のサイズの３倍にする
        let slit_length = birdSize.height * 3
        
        // 隙間位置の上下の揺れ幅を鳥のサイズの３倍とする
        let random_y_range = birdSize.height * 3
        
        
        //下の壁の、y軸方向で下限となる位置を計算（中央から下方向の最大揺れ幅で、下の壁を表示する位置）
        let groundSize = SKTexture(imageNamed: "ground").size()
        
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        
        //壁を生成するアクション
        let createWallAnimation = SKAction.run({
            
            //  壁関連のノードを載せるノード
            let wall = SKNode()
            
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            
            wall.zPosition = -50
            
            let random_y = CGFloat.random(in: 0..<random_y_range)
            
            // y軸の下限にランダムな値を足して、下の壁のy座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            
            
            //　下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            // スプライトに物理演算を設定　（７．２で追記）
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            
            // 7.4で追加  衝突のカテゴリ
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突時に動かないよう設定 (7.2で追加）
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            
            
            //　上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)

            
            // スプライトに物理演算を設定　（７．２で追記）
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            
            // 7.4で追加  衝突のカテゴリ
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突時に動かないよう設定 (7.2で追加）
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            // 7.4で追加　スコアUP用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory | self.itemCategory | self.heartCategory // アイテムとハートが重なっていたら、消したいので、衝突相手のカテゴリとして設定
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
            
        })
        
        // 次の壁製作までの時間待ちのアクション
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    
    
    // 鳥の精製・設定
    func setupBird() {
        
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // 2種類のテクスチャを交互に返納するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        
        let flap = SKAction.repeatForever(texturesAnimation)
        
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //　物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        // 7.4で追加　衝突したときに回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 7.4で追加  衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory   // 衝突時に、回転する             // 0...00110
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | itemCategory | heartCategory | deadlineCategory // 0...110110
    
        
        //アニメーションを設定
        bird.run(flap)
        
        addChild(bird)
        
    }
    
    // 鳥が画面のフレーム左端にまで押されてきて触れた時の判定用、デッドラインの設定
    func setupDeadline() {
        // 地面の色を読み込む
        let deadlineTexture = SKTexture(imageNamed: "wall")
        deadlineTexture.filteringMode = .nearest
        
        
        // deadline のスプライトを設置する
        let sprite = SKSpriteNode(texture: deadlineTexture)
        
        // 高さが足りないので、フレームの高さにまで拡大するための情報を入れた変数
        let magnifiedSize = CGSize(width: deadlineTexture.size().width, height: self.frame.size.height)
        sprite.scale(to: magnifiedSize)
        
        // スプライトの位置を決める時のX座標を決めるために必要
        let wallSize = SKTexture(imageNamed: "wall").size()
            
        // スプライトの表示する位置を指定
        sprite.position = CGPoint(
            x: 0 - wallSize.width / 2,  // フレームの左端
            y: self.frame.size.height / 2
            )
            
            
            // スプライトに物理演算を設定
            sprite.physicsBody = SKPhysicsBody(rectangleOf: deadlineTexture.size())
            
            // 7.4で追加　衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = deadlineCategory
            
            // 衝突時に動かないように設定 　(7.2で追加）
            sprite.physicsBody?.isDynamic = false
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
            
            // テスクチャを指定してスプライトを指定する
            let deadlineSprite = SKSpriteNode(texture: deadlineTexture)
            
            
            // スプライトの表示する位置を指定する
            deadlineSprite.position = CGPoint(
                x: 0 - wallSize.width / 2,
                y: self.frame.size.height / 2
            )
            
            // シーンにスプライトを追加する
            addChild(deadlineSprite)
    }
    
    
    
    
    // 課題　アイテムの生成・設定
    func setupItem() {
        
        // アイテムの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "item")
        itemTexture.filteringMode = .linear
        let itemSize = itemTexture.size() 
        
        // 移動する距離を計算
        // 画面上に止まって見えるようにするために、壁と同じ距離を同じ時間で移動させる（壁の幅を取得する）
        let wallSize = SKTexture(imageNamed: "wall").size()
        let movingDistance = CGFloat(self.frame.size.width + wallSize.width)
        
        // 画面外まで移動するアクションを作成
        // 壁と動きを合わせるため、durationは、wallと合わせ４に。
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        //自身を取り除くアクション
        let removeItem = SKAction.removeFromParent()
        
        // ２つのアニメーションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        // 鳥、地面のサイズを取得(出現するYの幅を決めるために必要）
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        let groundSize = SKTexture(imageNamed: "ground").size()
        
        // Y値の下限。地面から鳥３羽分にする
        let item_lowest_y = groundSize.height + birdSize.height * 3
        
        // y下限値の上に足す、maxのy値。（下限は、地面＋鳥3羽分。上限はframeの高さから、鳥3羽分まで。）
        let item_highest_y = self.frame.size.height - (groundSize.height + birdSize.height * (3 + 3))
        
        // アイテムを生成するアクションを作成
        let createItemAnimation = SKAction.run({
            
            // アイテム関連のノードを乗せるノードを作成
            let item = SKSpriteNode(texture: itemTexture)
            
            // アイテム発生のyの値を決定するためランダム値を生成
            let random_y = CGFloat.random(in: 0..<item_highest_y)
            
            // アイテムのY値を決定（Y下限＋ランダム値）
            let item_y = item_lowest_y + random_y
            
            // アイテムのポジション
            item.position = CGPoint(x: self.frame.size.width + itemSize.width, y: item_y)
            item.zPosition = -80    // 壁と当たって消す機能の実装ができなくても、アイテムが見えなくなるように、奥に配置（変更する可能性あり）
            
            // スプライトに物理演算を設定する
            item.physicsBody = SKPhysicsBody(rectangleOf: itemSize)
            item.physicsBody?.categoryBitMask = self.itemCategory
            //item.physicsBody?.contactTestBitMask = self.birdCategory | self.wallCategory   //壁とぶつかって生成したら消したかったが・・・ 壁には登録したが、念のためこちらにも。鳥の分は必要？
            
            
            //　衝突時、動かないように設定
            item.physicsBody?.isDynamic = false
            
            // 衝突判定をする対象を設定（鳥と壁）
            // 壁とぶつかる場所に生成したアイテムは、消したいが、壁側に設定する
            item.physicsBody?.contactTestBitMask = self.birdCategory //| self.wallCategory
            item.run(itemAnimation)
            self.itemNode.addChild(item)
        })
        
        
        // 次のアイテム生成までの時間待ちのアニメーション
        let waitAnimation = SKAction.wait(forDuration: 0.3)
        
        // 6/7で生成する (壁とぶつかったものは消したいので、多めに生成、でもランダムに見えるように間を開ける。多すぎるなら、7/5に減らす）
        let itemRandomCreate = SKAction.run({
            let random7 = Int.random(in: 0..<7)
            
            if random7 == 0 {
                return
                
            } else {
                self.itemNode.run(createItemAnimation)
            }
            
        })
        
        // アイテムの生成　-> 時間待ち　->生成　を無限に繰り返すアクション
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([itemRandomCreate, waitAnimation]))
        itemNode.run(repeatForeverAnimation)
        
    }  // --- ここまで、課題のsetupItem()
    
    
    // 課題　ハートの生成・設定
    func setupHeart() {
        
        // ハートの画像を読み込む
        let heartTexture = SKTexture(imageNamed: "heart")
        heartTexture.filteringMode = .linear
        let heartSize = heartTexture.size()
        
        // 移動する距離を計算
        // 画面上の同じ場所にあるように見えるようにするために、壁と同じ距離を同じ時間で移動させる（壁の幅を取得する）
        let wallSize = SKTexture(imageNamed: "wall").size()
        let movingDistance = CGFloat(self.frame.size.width + wallSize.width)
        
        // 画面外まで移動するアクションを作成
        // 壁と動きを合わせるため、durationは、wallと合わせ４に。
        let moveHeart = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        //自身を取り除くアクション
        let removeHeart = SKAction.removeFromParent()
        
        // ２つのアニメーションを順に実行するアクションを作成
        let heartAnimation = SKAction.sequence([moveHeart, removeHeart])
        
        // 鳥、地面のサイズを取得(出現するYの限度値を決めるために必要）
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        let groundSize = SKTexture(imageNamed: "ground").size()
        
        // 下限は、地面から鳥４羽分にする
        let heart_lowest_y = groundSize.height + birdSize.height * 4
        
        // y下限値の上に足す、maxのy値を求めておく（下は、地面＋鳥４羽分。上はframeの高さから、鳥5羽分まで。）
        let heart_highest_y = self.frame.size.height - (groundSize.height + birdSize.height * (4 + 5))
        
        // ハートを生成するアクションを作成
        let createHeartAnimation = SKAction.run({
            
            // ハート関連のノードを乗せるノードを作成
            let heart = SKSpriteNode(texture: heartTexture)
            
            // アイテム発生のyの値を決定するためランダム値を生成
            let random_y = CGFloat.random(in: 0..<heart_highest_y)
            
            // アイテムのY値を決定（Y下限＋ランダム値）
            let heart_y = heart_lowest_y + random_y
            
            // ハートのポジション
            heart.position = CGPoint(x: self.frame.size.width + heartSize.width, y: heart_y)
            heart.zPosition = -80    // 壁と当たって消す機能の実装ができなくても、アイテムが見えなくなるように、奥に配置（変更する可能性あり）
            
            // スプライトに物理演算を設定する
            heart.physicsBody = SKPhysicsBody(rectangleOf: heartSize)
            heart.physicsBody?.categoryBitMask = self.heartCategory
            //heart.physicsBody?.contactTestBitMask = self.wallCategory 壁とぶつかって生成されたら消したかったが・・・
            
            //　衝突時、動かないように設定
            heart.physicsBody?.isDynamic = false
            
            // 衝突判定をする対象を設定（鳥と壁）// 壁は、実装できなそうなら、消す
            // 壁とぶつかる場所に生成したアイテムは、消したい
            heart.physicsBody?.contactTestBitMask = self.birdCategory | self.wallCategory
            heart.run(heartAnimation)
            self.heartNode.addChild(heart)
        })
        
        
        
        // 次のハート生成までの時間待ちのアニメーション
        let waitAnimation = SKAction.wait(forDuration: 2.5)
        
        // 1/4で生成する
        let heartRandomCreate = SKAction.run({
            let random4 = Int.random(in: 0..<4)
            
            if random4 == 0 {
                return
                
            } else {
                self.heartNode.run(createHeartAnimation)
            }
            
        })
        
        // ハートの生成　-> 時間待ち　->生成　を無限に繰り返すアクション
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([heartRandomCreate, waitAnimation]))
        heartNode.run(repeatForeverAnimation)
        
    }  // --- ここまで、課題のsetupHeart()
    
    
    
    
    
    
    
    // 画面タップ時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if scrollNode.speed > 0 {
            
            //鳥の速度をzeroにする
            bird.physicsBody?.velocity = CGVector.zero
            
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
            
        } else if bird.speed == 0 {
            restart()
        }
    }
    
   
    
    
    // SKPhysicsContactDelegateのメソッド。
    // 衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        
        // ゲームオーバー時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        
        // & 演算子は、どちらも１の場合は１になる演算子
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            
            // スコア用の物体と衝突した場合
            print("ScoreUP")
            score += 1
            scoreLabelNode.text = "Score: \(score)" // 8.2で追加
            
            // ベストスコア更新かどうかを確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score: \(bestScore)" // 8.2で追加
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            
        // アイテムと衝突
        } else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory  {
            
            // 効果音を鳴らす
            itemGetPlayer.currentTime = 0
            itemGetPlayer.play()
            
            // アイテムを消去
            if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory {
                contact.bodyA.node?.removeFromParent()
                
            } else {
                contact.bodyB.node?.removeFromParent()
            }
            
            itemScore += 1
            itemScoreLabelNode.text = "Item Score: \(itemScore)"
            
         
        // ハートと衝突
        } else if (contact.bodyA.categoryBitMask & heartCategory) == heartCategory || (contact.bodyB.categoryBitMask & heartCategory) == heartCategory {
            
            heartGetPlayer.currentTime = 0
            heartGetPlayer.play()
            
            heartPoint += 1
            heartPointLabelNode.text = " ❤️ x \(heartPoint)"
            
            // ハートを消去
            if (contact.bodyA.categoryBitMask & heartCategory) == heartCategory {
                contact.bodyA.node?.removeFromParent()
                
            } else {
                contact.bodyB.node?.removeFromParent()
            }
            
            
            
            
        } else  if (contact.bodyA.categoryBitMask & deadlineCategory) == deadlineCategory || (contact.bodyB.categoryBitMask & deadlineCategory) == deadlineCategory {
            
            //deadlindeにぶつかった時（画面から見えなくなった時）
            crashPlayer.currentTime = 0 // 巻き戻しておく. play()後に巻き戻すべき？？
            crashPlayer.play()
            
            heartPoint = 0
            heartPointLabelNode.text = " ❤️ x \(heartPoint)"
            
            
            print("GameOver")
            gameOverLabelNode.isHidden = false // ゲームオーバーを表示
            
            //BGMを止める
            let stopPlaying = SKAction.stop()
            bgmNode.run(stopPlaying)
            self.bgmCreditLabelNode.isHidden = true
            
            
            // スクロールを停止させる
            scrollNode.speed = 0
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion: {
                self.bird.speed = 0
            })
            
            
            
        } else {
            //　壁か地面と衝突した
            crashPlayer.currentTime = 0 // 巻き戻しておく. play()後に巻き戻すべき？？
            crashPlayer.play()
            
             
            heartPoint -= 1
            heartPointLabelNode.text = " ❤️ x \(heartPoint)"
            
                            
             
            if heartPoint == 0 { // ハートがなくなってしまった
                 
                crashPlayer.play()
                crashPlayer.currentTime = 0
                 
                print("GameOver")
                gameOverLabelNode.isHidden = false  // ゲームオーバーを表示
                 
                //BGMを止める
                let stopPlaying = SKAction.stop()
                bgmNode.run(stopPlaying)
                self.bgmCreditLabelNode.isHidden = true
                 
                 
                 // スクロールを停止させる
                 scrollNode.speed = 0
                 bird.physicsBody?.collisionBitMask = groundCategory
                 
                 let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
                 bird.run(roll, completion: {
                     self.bird.speed = 0
                 })
                 
             } else if heartPoint > 0 {
                 return
             }
            
        }
        
        
    }
    
    
    func setupScoreLabel() {
        score = 0
        
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score: \(score)"
        self.addChild(scoreLabelNode)
        
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score: \(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score: \(itemScore)"
        self.addChild(itemScoreLabelNode)
        
        
        heartPoint = 1
        heartPointLabelNode = SKLabelNode()
        heartPointLabelNode.fontColor = UIColor.black
        heartPointLabelNode.position = CGPoint(x: self.frame.size.width - 30, y: self.frame.size.height - 60)
        heartPointLabelNode.zPosition = 100
        heartPointLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        heartPointLabelNode.text = "❤️ x \(heartPoint)"
        self.addChild(heartPointLabelNode)
        
    }
    
    
    func setupCreditLabel() {
        bgmCreditLabelNode = SKLabelNode()
        bgmCreditLabelNode.fontColor = UIColor.black
        bgmCreditLabelNode.fontSize = 8
        bgmCreditLabelNode.position = CGPoint(x: self.frame.size.width - 30, y: 20)
        bgmCreditLabelNode.zPosition = 100
        bgmCreditLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        bgmCreditLabelNode.text = "BGM: MusMus"
        self.addChild(bgmCreditLabelNode)
    }
    
    // 再スタート
    func restart() {
        
        score = 0
        scoreLabelNode.text = "Score: \(score)" // 8.2で追加
        
        itemScore = 0
        itemScoreLabelNode.text = "Item Score: \(itemScore)"
        
        heartPoint = 1
        heartPointLabelNode.text = "❤️ x \(heartPoint)"
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        itemNode.removeAllChildren()
        heartNode.removeAllChildren()
        
        // ゲームオーバー表示を隠す
        gameOverLabelNode.isHidden = true
        // BGMをもう一度再生する
        let restartPlaying = SKAction.play()
        bgmNode.run(restartPlaying)
        self.bgmCreditLabelNode.isHidden = false
        
        bird.speed = 1
        
        scrollNode.speed = 1
    }
    
    func setupGameOverLabel() {
        gameOverLabelNode = SKLabelNode()
        gameOverLabelNode.fontColor = UIColor.red
        gameOverLabelNode.fontSize = 60
        gameOverLabelNode.position = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
        gameOverLabelNode.zPosition = 100
        gameOverLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        gameOverLabelNode.text = "GAME OVER"
        self.addChild(gameOverLabelNode)

    }
    
}
