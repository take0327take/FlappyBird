//
//  GameScene.swift
//  FlappyBird
//
//  Created by TakeshiTakeuchi on 2016/09/12.
//  Copyright © 2016年 jp.techacademy.takeshi.takeuchi. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate,AVAudioPlayerDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var scoreNode:SKNode!
    var itemScoreNode:SKNode!
    
    /*
     ** 衝突判定カテゴリ
     */
    
    let birdCategory: UInt32 = 1 << 0         // 0...00001
    let groundCategory: UInt32 = 1 << 1       // 0...00010
    let wallCategory: UInt32 = 1 << 2         // 0...00100
    let scoreCategory: UInt32 = 1 << 3        // 0...01000
    let itemScoreCategory: UInt32 = 1 << 4    // 0...10000
    
    /*
     ** スコア用
     */
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    /*
     ** item用
     */
    var itemScore = 0
    var itemScoreLabelNode:SKLabelNode!

    /*
     ** background
     */
    let url = NSBundle.mainBundle().bundleURL.URLByAppendingPathComponent("background.mp3")
    var player:AVAudioPlayer!

    /*
     ** SKView上にシーンが表示された際に呼ばれるメソッド
     */
    override func didMoveToView(view: SKView) {
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        
        // 背景色を設定
        backgroundColor = UIColor(colorLiteralRed: 0.9019607843137255, green: 0.49411764705882355, blue:0.13333333333333333, alpha:1.0)
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        bird = SKSpriteNode()
        addChild(bird)
        
        scoreNode = SKLabelNode()
        addChild(scoreNode)
        
        bestScoreLabelNode = SKLabelNode()
        addChild(bestScoreLabelNode)
        
        itemScoreNode = SKNode()
        scrollNode.addChild(itemScoreNode)
        
        itemScoreLabelNode = SKLabelNode()
        addChild(itemScoreLabelNode)
        
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
        setupitem()
        //        setupitemScoreLabel()
        //        setupbestScoreLabel()
        
        // background音
//        let backmusic = SKAction.playSoundFileNamed("background.mp3", waitForCompletion: false)
////      let backmusicloop = SKAction.repeatActionForever(backmusic)
//        self.runAction(backmusic)

        do {
            //音楽を再生する。
            try player = AVAudioPlayer(contentsOfURL:url)
            //無限ループ
            player.numberOfLoops = -1
            
            player.play()

        } catch {
            print(error)
        }
        
        //デリゲート先を自分に設定する。
        self.physicsWorld.contactDelegate = self

        
    }
    
    
    
    /*
     ** スコアボード
     */
    
    func setupScoreLabel() {
        /*
         ** scoreの設定
         */
        
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.blackColor()
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        /*
         ** bestscoreの設定
         */
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.blackColor()
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        
        let bestScore = userDefaults.integerForKey("BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        /*
         ** itemの設定
         */
        
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.blackColor()
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemScoreLabelNode.zPosition = 100 // 一番手前に表示する
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        itemScoreLabelNode.text = "itemScore:\(score)"
        self.addChild(itemScoreLabelNode)
        
    }
    
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if scrollNode.speed > 0 {
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
            
            // 鳥が飛ぶ音
            let flyaction = SKAction.playSoundFileNamed("fly.mp3", waitForCompletion: false)
            self.runAction(flyaction)
            
        } else if bird.speed == 0 {
            restart()
        }
    }
    
    /*
     ** SKPhysicsCOntactDelegateのメソッド。衝突した際に呼ばれる
     */
    
    func didBeginContact(contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integerForKey("BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)" // ←追加
                userDefaults.setInteger(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        } else if
            // itemに当たった時の処理
            
            (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory
                || (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory {
            
            // item スコアの更新
            print("itemScoreUP")
            itemScore += 1
            itemScoreLabelNode.text = "itemScore:\(itemScore)"
            
            // item取得音
            let action = SKAction.playSoundFileNamed("item.mp3", waitForCompletion: false)
            self.runAction(action)
            
            // 自身を取り除くアクションを作成
//            let removeItem = SKAction.removeFromParent()
            contact.bodyA.node?.removeFromParent()
            
//            // 2つのアニメーションを順に実行するアクションを作成
//            let itemAnimation = SKAction.sequence([removeItem])

//            let item = SKNode()
//            item.runAction(itemAnimation)
            
        }
            
        else {
            // 壁か地面と衝突した
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotateByAngle(CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.runAction(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    
    
    /**
     * 地面関数
     */
    
    func setupGround(){
        // 地面の画像を表示
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        // 必要な枚数を設定
        let needNumber = 2.0 + (frame.size.width / groundTexture.size().width)
        
        // スクロールアクションを設定
        // 左方向に画像１枚分スクロールさせる設定
        let moveGround = SKAction.moveByX(-groundTexture.size().width , y: 0, duration: 5.0)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveByX(groundTexture.size().width, y: 0, duration: 0.0)
        
        // 左にスクロール→もとの位置→左にスクロールを無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatActionForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライトを配置する
        CGFloat(0).stride(to: needNumber, by: 1.0).forEach{ i in
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(x: i * sprite.size.width, y:groundTexture.size().height / 2)
            
            // スプライトにアクションを設定する
            sprite.runAction(repeatScrollGround)
            
            // スプライトに物理演算を追加する
            sprite.physicsBody = SKPhysicsBody(rectangleOfSize: groundTexture.size())
            
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            // 衝突時に動かないように設定する
            sprite.physicsBody?.dynamic = false
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    /**
     * 雲関数
     */
    
    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        // 必要な枚数を計算
        let needCloudNumber = 2.0 + (frame.size.width / cloudTexture.size().width)
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveByX(-cloudTexture.size().width , y: 0, duration: 20.0)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveByX(cloudTexture.size().width, y: 0, duration: 0.0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
        let repeatScrollCloud = SKAction.repeatActionForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        CGFloat(0).stride(to: needCloudNumber, by: 1.0).forEach { i in
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(x: i * sprite.size.width, y: size.height - cloudTexture.size().height / 2)
            
            // スプライトにアニメーションを設定する
            sprite.runAction(repeatScrollCloud)
            
            //スプライトに物理演算を
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    /**
     * 壁関数
     */
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .Linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveByX(-movingDistance, y: 0, duration:4.0)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.runBlock({
            
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50.0 // 雲より手前、地面より奥
            
            // 画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            
            // 壁のY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 4
            
            // 下の壁のY軸の下限
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 -  random_y_range / 2)
            
            // 1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            // キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 4
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            wall.addChild(under)
            
            // スプライトに物理演算を設定
            under.physicsBody = SKPhysicsBody(rectangleOfSize: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突時に動かないように設定
            under.physicsBody?.dynamic = false
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //スプライトに物理演算を設定
            upper.physicsBody = SKPhysicsBody(rectangleOfSize: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突時に動かないように設定
            upper.physicsBody?.dynamic = false
            
            wall.addChild(upper)
            
            // スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.dynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            wall.runAction(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        // 次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.waitForDuration(2)
        
        // 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatActionForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        runAction(repeatForeverAnimation)
    }
    
    
    /*
     ** item 関数
     */
    
    func setupitem() {
        // itemの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "item")
        itemTexture.filteringMode = .Linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + itemTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveItem = SKAction.moveByX(-movingDistance, y: 0, duration:4.0)
        
        // 自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        // itemを生成するアクションを作成
        let createItemAnimation = SKAction.runBlock({
            
            // item関連のノードを乗せるノードを作成
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0.0)
            item.zPosition = -50.0 // 雲より手前、地面より奥
            
            // 画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            
            // itemのY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 4
            
            // 下のitemのY軸の下限
            let under_item_lowest_y = UInt32( center_y - itemTexture.size().height / 2 -  random_y_range / 2)
            
            // 1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            _ = CGFloat(under_item_lowest_y + random_y)

            /*
             ** x軸設定
             */
//            // 画面のX軸の中央値
//            let center_x = self.frame.size.width / 2
            
            // itemのX座標を上下ランダムにさせるときの最大値
            let random_x_range = self.frame.size.width / 4
            
//            // 下のitemのX軸の下限
//            let under_item_lowest_x = UInt32( center_x - itemTexture.size().width / 2 -  random_x_range / 2)
//            
            // 1〜random_y_rangeまでのランダムな整数を生成
            let random_x = arc4random_uniform( UInt32(random_x_range) )
            
            // X軸の下限にランダムな値を足して、下の壁のY座標を決定
            _ = CGFloat(random_x)


            
            
//            // 下側のitemを作成
//            let under = SKSpriteNode(texture: itemTexture)
//            under.position = CGPoint(x: 0.0, y: under_item_y)
//            item.addChild(under)
            
//            // スプライトに物理演算を設定
//            under.physicsBody = SKPhysicsBody(rectangleOfSize: itemTexture.size())
//            under.physicsBody?.categoryBitMask = self.itemScoreCategory
//            
//            // 衝突時に動かないように設定
//            under.physicsBody?.dynamic = false

            
//            // 上側のitemを作成
//            let upper = SKSpriteNode(texture: itemTexture)
//            upper.position = CGPoint(x: under_item_x + itemTexture.size().width,
//                y: under_item_y + itemTexture.size().height)
//            
//            //スプライトに物理演算を設定
//            upper.physicsBody = SKPhysicsBody(rectangleOfSize: itemTexture.size())
//            upper.physicsBody?.categoryBitMask = self.itemScoreCategory
//            
//            //衝突時に動かないように設定
//            upper.physicsBody?.dynamic = false
//            
//            item.addChild(upper)
//            // スコアアップ用のノード
//            let itemScoreNode = SKNode()
//            itemScoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
//            itemScoreNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: upper.size.width, height: self.frame.size.height))
//            itemScoreNode.physicsBody?.dynamic = false
//            itemScoreNode.physicsBody?.categoryBitMask = self.itemScoreCategory
//            itemScoreNode.physicsBody?.contactTestBitMask = self.birdCategory
//
//            item.addChild(itemScoreNode)
            
            let item_lowest_y = UInt32( center_y - itemTexture.size().height / 2 -  random_y_range / 2)
            let item_y = CGFloat(item_lowest_y + random_y)
            
            let itemApple = SKSpriteNode(texture: itemTexture)
            itemApple.position = CGPoint(x: 0.0, y: item_y)
            itemApple.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: itemApple.size.width, height: itemApple.size.height))
            itemApple.physicsBody?.dynamic = false
            itemApple.physicsBody?.categoryBitMask = self.itemScoreCategory
            itemApple.physicsBody?.contactTestBitMask = self.birdCategory
            
            item.addChild(itemApple)
 
            
            
            item.runAction(itemAnimation)
            
            self.itemScoreNode.addChild(item)
        })
        
        // 次のitem作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.waitForDuration(2)
        
        // itemを作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatActionForever(SKAction.sequence([createItemAnimation, waitAnimation]))
        
        runAction(repeatForeverAnimation)
    }
    
    
    
    /**
     * 鳥関数
     */
    
    func setupBird(){
        // 鳥の画像を２種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = SKTextureFilteringMode.Linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = SKTextureFilteringMode.Linear
        
        // 2種類のテクスチャを交互に変更するアニメーション
        let texureAnimation = SKAction.animateWithTextures([birdTextureA,birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatActionForever(texureAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: 30, y: self.frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        // 衝突した際回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        // アニメーション作成
        bird.runAction(flap)
        
        // スプライトを作成する
        addChild(bird)
    }
    
    /*
     ** リスタート処理
     */
    func restart() {
        score = 0
        scoreLabelNode.text = String("Score:\(score)")
        itemScore = 0
        itemScoreLabelNode.text = String("itemScore:\(score)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    
}
