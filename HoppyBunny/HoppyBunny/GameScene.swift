//
//  GameScene.swift
//  HoppyBunny
//
//  Created by Matthew Lee on 1/4/17.
//  Copyright © 2017 Matthew Lee. All rights reserved.
//

import SpriteKit
import GameplayKit

enum GameSceneState {
    case active, gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    /** Game Management */
    var gameState: GameSceneState = .active //default active
    var hero: SKSpriteNode!
    var sinceTouch: CFTimeInterval = 0
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 /** 60 FPS */
    var groundA: SKSpriteNode!
    var groundB: SKSpriteNode!
    let scrollSpeed: CGFloat = 100
    var scrollLayer: SKNode!
    var obstacleSource: SKNode!
    var obstacleLayer: SKNode!
    var spawnTimer: CFTimeInterval = 0
    var buttonRestart: MSButtonNode!
    var scoreLabel: SKLabelNode!
    var points = 0
    
    override func didMove(to view: SKView) {
        /** set up your scene here
    
        */
        //you are recursively searching for the hero variable. doing '//' recursively searches
        hero = self.childNode(withName: "//hero") as! SKSpriteNode
        
        /* set reference to scroll layer */
        scrollLayer = self.childNode(withName: "scrollLayer")
        
        /* make reference to ground sprites */
        groundA = self.childNode(withName: "//groundA") as! SKSpriteNode!
        groundB = self.childNode(withName: "//groundB") as! SKSpriteNode!
        
        /* set reference to obstacle Source node */
        obstacleSource = self.childNode(withName: "obstacle")
        
        /* set reference to obstacle layer node */
        obstacleLayer = self.childNode(withName: "obstacleLayer")
        
        /* set physics contact delegate */
        //assigns game scene to delegate
        physicsWorld.contactDelegate = self
        
        /* set UI connections */
        buttonRestart = self.childNode(withName: "buttonRestart") as! MSButtonNode
        
        /** setup score label */
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        
        /* set up button restart handler */
        buttonRestart.selectedHandler = {
            /* grab reference to our spritekit view */
            let skView = self.view as SKView!
            
            /* load game scene */
            let scene = GameScene(fileNamed: "GameScene") as GameScene!
            
            /* ensure correct aspect mode */
            scene?.scaleMode = .aspectFill
            
            /* restart game scene */
            skView?.presentScene(scene)
        }
        
        /** hide restart button */
        buttonRestart.state = .MSButtonNodeStateHidden
        
        /* reset score label */
        scoreLabel.text = "\(points)"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /** called when a touch BEGINS */
        
        /* disables touch if game is not active */
        if gameState != .active { return }
        
        /* reset velocity, helps improve response against falling velocity */
        hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
 
        /* apply vertical impulse */
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))
        
        /** apply subtle rotation */
        hero.physicsBody?.applyAngularImpulse(1)
        
        /** reset touch timer */
        self.sinceTouch = 0
    }
    
    //limiting upward velocity of bunny. update method is called in every frame
    override func update(_ currentTime: CFTimeInterval) {
        /** called before each frame is rendered */
        
        /** skip game update if game is no longer active */
        if gameState != .active { return }
        
        /* grab current velocity */
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        /** check and cap current velocity */
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
        
        /* Apply falling rotation */
        if sinceTouch > 0.1 {
            let impulse = -20000 * fixedDelta
            hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        /** clamp rotation */
        //.clamp means that the float values will stay within the float values, inclusive
        hero.zRotation.clamp(v1: CGFloat(-90).degreesToRadians(), CGFloat(30).degreesToRadians())
        hero.physicsBody?.angularVelocity.clamp(v1: -2, 2)
        
        /** Update last touch timer */
        sinceTouch += fixedDelta
        
        /* scroll the ground sprites */
        scrollSprite(groundA, speed: 5)
        scrollSprite(groundB, speed: 5)
        
        /* DO CLOUDS! */
        
        /* process world scrolling */
        scrollWorld()
        
        /* process obstacles */
        updateObstacles()
        spawnTimer+=fixedDelta
    }
    
    func scrollSprite(_ sprite: SKSpriteNode, speed: CGFloat) {
        sprite.position.x -= speed
        
        if sprite.position.x < sprite.size.width / -2 {
            sprite.position.x += sprite.size.width * 2
        }
    }
    
    func scrollWorld() {
        /* scroll world */
        //very good programming practice to declare scroll speed as a global variable. 
        //this makes it easy to debug and etc.
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* loop through scroll layer nodes */
        for ground in scrollLayer.children as! [SKSpriteNode] {
            /* get ground node position, convert node position to scene space */
            let groundPosition = scrollLayer.convert(ground.position, to: self)
            
            /* check if ground sprite has left the scene */
            if groundPosition.x <= -ground.size.width / 2 {
                /* reposition ground sprite to second starting position */
                let newPosition = CGPoint(x: (self.size.width / 2) + ground.size.width, y: groundPosition.y)
                /** convert new node position back to scroll layer space */
                ground.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
    
    func updateObstacles() {
        /* update obstacles*/
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            /** loop through obstacle layer nodes */
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)
            
            /* check if obstacle has left the scene */
            if obstaclePosition.x <= -groundA.size.width / 2 {
                /* remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
            }
        }
        
        /* time to add random obstacles */
        if spawnTimer >= 1 {
            /** create a new obstacle by copying the source obstacle */
            let newObstacle = obstacleSource.copy() as! SKNode
            obstacleLayer.addChild(newObstacle)
            
            /** start new obstacle position, just outside of screen, with random y value */
            let randomPosition = CGPoint(x: 352, y: CGFloat.random(min: 234, max: 382))
            
            /** convert new node position back to obstacle layer space */
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)
            
            /** reset spawn timer */
            spawnTimer = 0
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        /** hero touches anything, game over */
        //occurs when anything i want to know about touches something. (ones with contact mask 1)
        
        /* get references to bodies involved in collision */
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        
        /* get references to physics body nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        /* did our hero pass through the goal? */
        if nodeA.name == "goal" || nodeB.name == "goal" {
            /* increment points */
            points += 1
            
            /* update score label */
            scoreLabel.text = String(points)
            
            /*we can return now*/
            return
        }
        
        /* ensure only called when game running */
        if gameState != .active { return }
        
        /** change gamestate to game over */
        gameState = .gameOver
        
        /* stop any angular velocity from being applied */
        hero.physicsBody?.allowsRotation = false
        
        /* resets angular velocity */
        hero.physicsBody?.angularVelocity = 0
        
        /* stop hero flapping animation */
        hero.removeAllActions()
        
        /* create our hero death action */
        let heroDeath = SKAction.run({
            /** hero face in dirt */
            self.hero.zRotation = CGFloat(-90).degreesToRadians()
        })
        
        /* run action */
        hero.run(heroDeath)
        
        /** load the shake action resource */
        let shakeScene:SKAction = SKAction.init(named: "Shake")!
        
        /** loop through all nodes */
        for node in self.children {
            /*apply effect each ground node */
            node.run(shakeScene)
        }
        
        /* show restart button */
        buttonRestart.state = .MSButtonNodeStateActive
    }
}
