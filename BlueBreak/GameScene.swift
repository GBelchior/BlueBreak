//
//  GameScene.swift
//  BlueBreak
//
//  Created by Student on 7/18/16.
//  Copyright (c) 2016 Student. All rights reserved.
//

import SpriteKit
import GameplayKit

let BallCategoryName = "ball"
let PaddleCategoryName = "paddle"
let BlockCategoryName = "block"
let GameMessageName = "gameMessage"

let BallCategory   : UInt32 = 0x1 << 0
let TopCategory : UInt32 = 0x1 << 1
let BlockCategory  : UInt32 = 0x1 << 2
let PaddleCategory : UInt32 = 0x1 << 3
let BorderCategory : UInt32 = 0x1 << 4

class GameScene: SKScene, SKPhysicsContactDelegate  {
    
    var blocosRestantes = 35
    
    var isFingerOnScreen = false
    var touchLocation: CGFloat = 0.0
    var paddle: SKSpriteNode!
    var ball: SKSpriteNode!
    var paddleVelocity = 0.0
    
    let velocityMultiplicationFactor = 128.0
    let initialVelocity = 8.0
    
    var lastUpdateTime = 0.0
    
    var multiplayerService = MultiplayerServiceManager()
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        WaitingForTap(scene: self),
        Playing(scene: self),
        GameOver(scene: self)])
    
    var gameWon : Bool = false {
        didSet {
            let gameOver = childNodeWithName(GameMessageName) as! SKSpriteNode
            let textureName = gameWon ? "YouWon" : "GameOver"
            let texture = SKTexture(imageNamed: textureName)
            let actionSequence = SKAction.sequence([SKAction.setTexture(texture),
                SKAction.scaleTo(1.0, duration: 0.25)])
            
            gameOver.runAction(actionSequence)
        }
    }

    
    override func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        self.multiplayerService.delegate = self
        
        self.paddle = childNodeWithName(PaddleCategoryName) as! SKSpriteNode
        self.ball = childNodeWithName(BallCategoryName) as! SKSpriteNode
        
        self.ball.physicsBody!.friction = 0
        self.ball.physicsBody!.restitution = 1
        self.ball.physicsBody!.linearDamping = 0
        self.ball.physicsBody!.angularDamping = 0
        
        //Barreira em volta da tela, para a bola não escapar
        let borderBody = SKPhysicsBody(edgeLoopFromRect: self.frame)
        borderBody.friction = 0
        self.physicsBody = borderBody
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self
        
        //let paddle = childNodeWithName(PaddleCategoryName) as! SKSpriteNode
        //self.ball = childNodeWithName(BallCategoryName) as! SKSpriteNode
        //ball.physicsBody!.applyImpulse(CGVector(dx: 2.0, dy: -2.0))
        
        let topRect = CGRect(x: frame.origin.x, y: frame.size.height - 1, width: frame.size.width, height: 1)
        let top = SKNode()
        top.physicsBody = SKPhysicsBody(edgeLoopFromRect: topRect)
        addChild(top)
        
        top.physicsBody!.categoryBitMask = TopCategory
        ball.physicsBody!.categoryBitMask = BallCategory
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        borderBody.categoryBitMask = BorderCategory
        
        paddleVelocity = initialVelocity
        
        // 1
        let cols = 7
        let numberOfBlocks = 5
        //blocosRestantes = cols * numberOfBlocks // calcula quantos blocos o jogador possui no total
        let espacamento = 1.4
        let blockWidth = SKSpriteNode(imageNamed: "block").size.width
        let totalBlocksWidth = (CGFloat(numberOfBlocks) * blockWidth + CGFloat(espacamento) * CGFloat(numberOfBlocks))
        // 2
        let xOffset = CGFloat(CGRectGetWidth(frame) - totalBlocksWidth) / 6
        var dir : String
        
        // Contrucao dos blocos ao iniciar o jogo
        for j in 1...cols {
            for i in 0..<numberOfBlocks {
                
                if(i < 2) {
                    dir = "Left"
                }
                else if (i == 2) {
                    dir = "Center"
                }
                else {
                    dir = "Right"
                }
                let block = SKSpriteNode(imageNamed: "block\(dir).png")
                
                let positionX = xOffset + CGFloat(CGFloat(i) * CGFloat(espacamento) + 0.40) * blockWidth
                let positionY = CGRectGetHeight(frame) * 0.05 * CGFloat(j) + 32.5
                
                block.position = CGPoint(x: positionX, y: positionY)
            
                block.physicsBody = SKPhysicsBody(rectangleOfSize: block.frame.size)
                
                // Deixa os blocos curvados
                switch i {
                    case 0:
                        block.zRotation = -3.4
                    case 1:
                        block.position.y += 12
                        block.zRotation = 3
                    case 2:
                        block.position.y += 16
                    case 3:
                        block.position.y += 12
                        block.zRotation = -3
                    case 4:
                        block.zRotation = 3.4
                    default:
                        break
                }
                
                block.physicsBody!.allowsRotation = false
                block.physicsBody!.friction = 0.0
                block.physicsBody!.affectedByGravity = false
                block.physicsBody!.dynamic = false
            
                block.name = BlockCategoryName
                block.physicsBody!.categoryBitMask = BlockCategory
                block.zPosition = 5
                addChild(block)
            }
        }
        ball.physicsBody!.contactTestBitMask = TopCategory | BlockCategory
        
        let gameMessage = SKSpriteNode(imageNamed: "TapToPlay")
        gameMessage.name = GameMessageName
        gameMessage.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        gameMessage.zPosition = 4
        gameMessage.setScale(0.0)
        addChild(gameMessage)
        
        gameState.enterState(WaitingForTap)
        
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        
    if gameState.currentState is Playing {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        // 2
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA

        }
        // 3
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == TopCategory {
            // Bluetooth
            
            if self.multiplayerService.session.connectedPeers.count > 0 && ball.alpha == 1 {
                let x = self.size.width - ball.position.x
                let xv = -ball.physicsBody!.velocity.dx
                let yv = ball.physicsBody!.velocity.dy
                
                ball.alpha = 0
                ball.physicsBody!.velocity.dx = 0
                ball.physicsBody!.velocity.dy = 0
                ball.position.y = self.size.height - 18
                
                self.multiplayerService.sendBallDataToPeers(x, xV: xv, yV: yv)
            }
        }
        
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BlockCategory {
            secondBody.node!.removeFromParent()
            blocosRestantes -= 1
            print(blocosRestantes)
        }
    }
    }
    
    func breakBlock(node: SKNode) {
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first
        touchLocation = touch!.locationInNode(self).x
        isFingerOnScreen = true
        
        switch gameState.currentState {
        case is WaitingForTap:
            gameState.enterState(Playing)
            isFingerOnScreen = true
            
        case is Playing:
            let touch = touches.first
            let touchLocation = touch!.locationInNode(self)
            
            if let body = physicsWorld.bodyAtPoint(touchLocation) {
                if body.node!.name == PaddleCategoryName {
                    isFingerOnScreen = true
                }
            }
        case is GameOver:
            let newScene = GameScene(fileNamed:"GameScene")
            newScene!.scaleMode = .AspectFit
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            self.view?.presentScene(newScene!, transition: reveal)
            
        default:
            break
        }

    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isFingerOnScreen = false
        touchLocation = 0.0
        paddleVelocity = initialVelocity
    }
   
    override func update(currentTime: CFTimeInterval) {
        
        gameState.updateWithDeltaTime(currentTime)
        
        if(blocosRestantes == 0)
        {
            gameState.enterState(GameOver)
            gameWon = false
        }
        
        if (isFingerOnScreen) {
            paddleVelocity += velocityMultiplicationFactor * (currentTime - lastUpdateTime)
            MovePaddle(touchLocation)
        }
        lastUpdateTime = currentTime
    }
    
    func getBlocosRestantes() -> Int {
        return blocosRestantes
    }
    
    func MovePaddle(touchLocation: CGFloat) {
        //Se o usuário tocar na parte esquerda da tela, mover a raquete para a esquerda
        if touchLocation < self.size.width / 2 {
            //Checar se a raquete vai sair da tela
            if paddle.position.x - paddle.size.width / 2 - CGFloat(paddleVelocity) + 1 > 0 {
                paddle.position.x -= CGFloat(paddleVelocity)
            }
            else {
                paddle.position.x = paddle.size.width / 2 + 1
            }
        }
        //Caso contrário, mover para a direita
        else {
            //Checar se a raquete vai sair da tela
            if paddle.position.x + paddle.size.width / 2 + CGFloat(paddleVelocity) - 1 < self.size.width {
                paddle.position.x += CGFloat(paddleVelocity)
            }
            else {
                paddle.position.x = self.size.width - paddle.size.width / 2 - 1
            }
        }
    }
    
    func randomFloat(from from:CGFloat, to:CGFloat) -> CGFloat {
        let rand:CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
        return (rand) * (to - from) + from
    }
    
}

extension GameScene : MultiplayerServiceDelegate {
    func receiveBall(xPos: CGFloat, xV: CGFloat, yV: CGFloat) {
        self.ball.physicsBody!.velocity.dx = 0
        self.ball.physicsBody!.velocity.dy = 0
        
        self.ball.position.x = xPos
        self.ball.position.y = self.size.height - 18
        self.ball.physicsBody!.velocity = CGVectorMake(xV, yV)
        //self.ball.physicsBody!.velocity.dx = xV
        //self.ball.physicsBody!.velocity.dy = yV
        self.ball.alpha = 1
    }
}
