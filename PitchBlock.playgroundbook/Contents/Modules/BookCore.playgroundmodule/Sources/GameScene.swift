//
//  GameScene.swift
//  MusicGameTest
//
//  Created by ZouYa on 2021/3/5.
//

import UIKit
import SpriteKit
import AVFoundation

public class GameScene: SKScene{
    
    var pitchData: CGFloat = 0{
        didSet{
            DispatchQueue.main.async { [self] in
                checkSquareUIForPitch(pitch: pitchData)
                if currentBlocks != [] {
                    let nBlock = currentBlocks[0]
                    checkForEffect(nBlock: nBlock, curPitch: convertPitchToNote(pitch: pitchData))
                }
            }
        }
    }
    
    
    let nodeSpeed:CGFloat = 90
    var pianoVoicePlayer = AVAudioPlayer()
    
    var squareOne = SKShapeNode()
    var squareTwo = SKShapeNode()
    var squareThree = SKShapeNode()
    var squareFour = SKShapeNode()
    var squareFive = SKShapeNode()
    var squareSix = SKShapeNode()
    var squareSeven = SKShapeNode()
    
    var squareLower = SKShapeNode()
    var squareHigher = SKShapeNode()
    
    var labelForOne = SKLabelNode()
    var labelForTwo = SKLabelNode()
    var labelForThree = SKLabelNode()
    var labelForFour = SKLabelNode()
    var labelForFive = SKLabelNode()
    var labelForSix = SKLabelNode()
    var labelForSeven = SKLabelNode()
    
    var currentSquare:[SKShapeNode] = []
    var labelForSquare:[SKLabelNode] = []
    
    var block = SKSpriteNode()
    var currentBlocks:[SKSpriteNode] = []
    
    var effect = SKEmitterNode()
    var curShowBlock:[SKSpriteNode] = []
    var musicalNote = MusicalNote()
    
    var missTip = SKSpriteNode()
    var goodTip = SKSpriteNode()
    var perfectTip = SKSpriteNode()
    var isThreeHit:Int = 0
    
    public override func update(_ currentTime: TimeInterval) {
        
    }
    
    
}

