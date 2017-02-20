//
//  GameScene.swift
//  Project23_Space_Race
//
//  Created by Xiaoheng Pan on 11/13/16.
//  Copyright © 2016 Xiaoheng Pan. All rights reserved.
//

import SpriteKit
import GameplayKit

enum CollisonType: UInt32 {
    case none = 0
    case player = 1
    case ammo = 2
    case enemy = 4
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starfield: SKEmitterNode!
    var player: SKSpriteNode!
    var ammo: SKSpriteNode!
    var enemy: SKSpriteNode!
    var gameScore: SKLabelNode!
    var score: Int = 0 {
        didSet { // didSet a property observer used to update gameScore
            gameScore.text = "Score: \(score)"
        }
    }
    
    var possibleEnemies = ["ball", "hammer", "tv"]
    var gameTimer: Timer! // Used to create enemies regularly.
    var isGameOver = false //  a boolean that will be set to true when we should stop increasing the player's score
    
    override func didMove(to view: SKView) {
        
        backgroundColor = UIColor.black
        
        // The starfield particle emitter is positioned at X:1024 Y:384. If you created particles like this normally it would look strange, because most of the screen wouldn't start with particles and they would just stream in from the right. But by using the advanceSimulationTime() method of the emitter we're going to ask SpriteKit to simulate 10 seconds passing in the emitter, thus updating all the particles as if they were created 10 seconds ago. This will have the effect of filling our screen with star particles.
        starfield = SKEmitterNode(fileNamed: "Starfield")!
        starfield.position = CGPoint(x: size.width, y: size.height / 2)
        starfield.advanceSimulationTime(10)
        addChild(starfield)
        starfield.zPosition = -1
        
        player = SKSpriteNode(imageNamed: "player")
        player.name = "player"
        player.position = CGPoint(x: size.width * 0.1, y: size.height / 2)
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.categoryBitMask = CollisonType.player.rawValue
        player.physicsBody?.collisionBitMask = CollisonType.none.rawValue // Setting this to zero will prevent objects from bouncing off each other
        player.physicsBody!.contactTestBitMask = CollisonType.enemy.rawValue
        addChild(player)
        
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.text = "Score: 0"
        gameScore.horizontalAlignmentMode = .left
        gameScore.position = CGPoint(x: size.width * 0.03, y: size.height * 0.03)
        addChild(gameScore)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0) // Required, b/c default is -9.8
        physicsWorld.contactDelegate = self
     
        gameTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(createEnemy), userInfo: nil, repeats: true)
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(createAmmo), userInfo: nil, repeats: true)
        
    }
    
    func createAmmo() {
        if isGameOver {
            return
        }
        
        ammo = SKSpriteNode(imageNamed: "bullet")
        ammo.name = "ammo"
        ammo.position = CGPoint(x: player.position.x + 100, y: player.position.y)
        addChild(ammo)
        
        ammo.physicsBody = SKPhysicsBody(texture: ammo.texture!, size: ammo.size)
        ammo.physicsBody?.categoryBitMask = CollisonType.ammo.rawValue
        ammo.physicsBody?.contactTestBitMask = CollisonType.enemy.rawValue
        ammo.physicsBody?.collisionBitMask = CollisonType.none.rawValue // Setting this to zero will prevent objects from bouncing off each other
        ammo.physicsBody?.usesPreciseCollisionDetection = true
        
        ammo.physicsBody?.velocity = CGVector(dx: 900, dy: 0)
        ammo.physicsBody?.linearDamping = 0
        ammo.physicsBody?.angularDamping = 0
        
    }
    
    func createEnemy() {
        possibleEnemies = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleEnemies) as! [String]
        let randomDistribution = GKRandomDistribution(lowestValue: 50, highestValue: 736)
        
        enemy = SKSpriteNode(imageNamed: possibleEnemies[0])
        enemy.name = "enemy"
        enemy.position = CGPoint(x: Int(size.width * 1.2), y: randomDistribution.nextInt())
        addChild(enemy)
        
        enemy.physicsBody = SKPhysicsBody(texture: enemy.texture!, size: enemy.size)
        enemy.physicsBody?.categoryBitMask = CollisonType.enemy.rawValue
        enemy.physicsBody?.contactTestBitMask = CollisonType.ammo.rawValue
        enemy.physicsBody?.collisionBitMask = CollisonType.none.rawValue // Setting this to zero will prevent objects from bouncing off each other
        enemy.physicsBody?.usesPreciseCollisionDetection = true
        
        enemy.physicsBody?.velocity = CGVector(dx: -300, dy: 0)
        enemy.physicsBody?.angularVelocity = 5
        enemy.physicsBody?.linearDamping = 0
        enemy.physicsBody?.angularDamping = 0
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        for node in children {
            if node.position.x < size.width * -0.2 || node.position.y < size.height * -0.2 || node.position.y > size.height * 1.2 {
                node.removeFromParent()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var location = touch.location(in: self)
        
        if location.y < size.height * 0.05 {
            location.y = size.height * 0.05
        } else if location.y > size.height * 0.95 {
            location.y = size.height * 0.95
        } else if location.x < size.width * 0.05 {
            location.x = size.width * 0.05
        } else if location.x > size.width * 0.95 {
            location.x = size.width * 0.95
        }
        
        player.position = location
    }
    
    func ammoCollided(ammo: SKSpriteNode, enemy: SKSpriteNode) {
        
        let explosion = SKEmitterNode(fileNamed: "explosion")!
        explosion.position = enemy.position
        addChild(explosion)
        
        ammo.removeFromParent()
        enemy.removeFromParent()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.node?.name == "player" || secondBody.node?.name == "player" {
            isGameOver = true
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        
        if ((firstBody.categoryBitMask != 0) && (secondBody.categoryBitMask != 0)) {
            if firstBody.node != nil && secondBody.node != nil {
                ammoCollided(ammo: firstBody.node as! SKSpriteNode, enemy: secondBody.node as! SKSpriteNode)
                score += 100
            }
        }
    }

}
