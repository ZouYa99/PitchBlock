//
//  GameScene+UI.swift
//  MusicGameTest
//
//  Created by ZouYa on 2021/3/24.
//

import UIKit
import SpriteKit
import AVFoundation

extension GameScene{
    
    public override func didMove(to view: SKView) {
        setupUI(to: view)
    }
    
    //根据当前音高检测UI的画法
    func checkSquareUIForPitch(pitch:CGFloat){
        let note = convertPitchToNote(pitch: pitch)
        let index = returnIndexForPitch(pitch: note)
        if index != -1 {
            for i in 0..<7{
                if i == index {
                    currentSquare[i].fillColor = #colorLiteral(red: 0.8862745098, green: 0.8823529412, blue: 0.8941176471, alpha: 1)
                    labelForSquare[i].fontColor = .black
                    squareLower.alpha = 0
                    squareHigher.alpha = 0
                }else{
                    currentSquare[i].fillColor = #colorLiteral(red: 0.4549019608, green: 0.4588235294, blue: 0.6078431373, alpha: 1)
                    squareLower.alpha = 0
                    squareHigher.alpha = 0
                }
            }
        }
        if index == -1 {
            for i in 0..<7{
                currentSquare[i].fillColor = #colorLiteral(red: 0.4549019608, green: 0.4588235294, blue: 0.6078431373, alpha: 1)
                labelForSquare[i].fontColor = .white
            }
            if pitch < 59.5 {
                squareLower.alpha = 1
                squareHigher.alpha = 0
            }
            if pitch >= 71.5 {
                squareLower.alpha = 0
                squareHigher.alpha = 1
            }
        }
    }
    
    func finishThisGame(){
        squareLower.alpha = 0
        squareHigher.alpha = 0
        goodTip.alpha = 0
        perfectTip.alpha = 0
        missTip.alpha = 0
    }
    
    func removeBlockProduce(){
        self.removeAllActions()
        for curBlock in currentBlocks {
            curBlock.removeFromParent()
        }
        currentBlocks = []
    }
    
    func removeShowBlock(){
        self.removeAllActions()
        for curBlock in curShowBlock {
            curBlock.removeFromParent()
        }
        curShowBlock = []
    }
    
    //负责下落block
    func produceNewBlockFromJson(mode:String){
        var noteArray:[NoteData] = []
        var gapTime:[Double] = []
        if(mode == "Sing"){
            noteArray = readNoteFromJson(file: "TwinkleTwinkleLittleStar")
            gapTime = readGapTimeFromJson(file: "StarGapTime")
        }else if(mode == "Practice"){
            noteArray = readNoteFromJson(file: "Practice")
            gapTime = readGapTimeFromJson(file: "PracticeGapTime")
        }
        var index = 0
        for i in 0..<gapTime.count {
            gapTime[i]+=noteArray[i].continuanceTime
            print(gapTime[i])
        }
        self.run(.sequence([
            .repeat(.sequence([
                SKAction.run({ [self] in
                    addBlock(string: noteArray[index].note, time: noteArray[index].continuanceTime)
                    index += 1
                }),
                .wait(forDuration: TimeInterval(gapTime[index]))
            ]), count: gapTime.count),
            SKAction.run({ [self] in
                addBlock(string: noteArray[noteArray.count - 1].note, time: noteArray[noteArray.count - 1].continuanceTime)
            }),
            SKAction.wait(forDuration: TimeInterval((screen_height - itemWidth + block.size.height) / nodeSpeed) + 0.5),
            SKAction.run { [self] in
                NotificationCenter.default.post(name: NSNotification.Name("GameOver"), object: self, userInfo: nil)
            }
        ]))
    }
    //负责演示block的效果
    func showBlockAndEffect(){
        var index = 0
        var flag = true
        self.run(.repeat(.sequence([
            SKAction.run({ [self] in
                addSequenceBlock(index: index)
                if(flag){
                    showEffect()
                }
                flag = false
            }),
            .wait(forDuration: 1.3),
            SKAction.run {
                index += 1
            }
        ]), count: 7))
    }
    //负责演示的block的产生
    func addSequenceBlock(index:Int){
        let cur = musicalNote.SingleNote(Number: index)
        addChild(cur)
        curShowBlock.append(cur)
        let minY = 80 - block.size.height
        let duration = (screen_height - minY) / nodeSpeed
        let move = SKAction.moveTo(y: minY, duration: TimeInterval(duration))
        cur.run(move,withKey: "move")
    }
    //负责演示的效果
    func showEffect(){
        var index = 0
        let waitTime = (screen_height - 80) / nodeSpeed
        self.run(.sequence([
            SKAction.wait(forDuration: TimeInterval(waitTime)),
            .repeat(SKAction.sequence([
            SKAction.run { [self] in
                hitEffect(index: index)
            },
            .wait(forDuration: TimeInterval(0.4)),
            SKAction.run { [self] in
                currentSquare[index].fillColor = #colorLiteral(red: 0.4549019608, green: 0.4588235294, blue: 0.6078431373, alpha: 1)
                labelForSquare[index].fontColor = .white
                effect.alpha = 0
                curShowBlock[0].removeFromParent()
                curShowBlock.remove(at: 0)
            },
            SKAction.run {
                index += 1
            },
                SKAction.wait(forDuration: 0.9)
        ]), count: 6),
            SKAction.run { [self] in
                hitEffect(index: index)
            },
            .wait(forDuration: TimeInterval(0.4)),
            SKAction.run { [self] in
                currentSquare[index].fillColor = #colorLiteral(red: 0.4549019608, green: 0.4588235294, blue: 0.6078431373, alpha: 1)
                labelForSquare[index].fontColor = .white
                effect.alpha = 0
                curShowBlock[0].removeFromParent()
                curShowBlock.remove(at: 0)
            },
            SKAction.wait(forDuration: 0.2),
            SKAction.run { [self] in
                NotificationCenter.default.post(name: NSNotification.Name("ShowEffectEnd"), object: self, userInfo: nil)
            }
        ]))
    }
    //负责单音命中特效
    func hitEffect(index:Int){
        let path = Bundle.main.path(forResource: "PianoStandardVoice//\(index+1).mp3", ofType: nil)
        let soundUrl = URL(fileURLWithPath: path!)
        
        try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        pianoVoicePlayer = try! AVAudioPlayer(contentsOf: soundUrl)
        
        pianoVoicePlayer.numberOfLoops = 0
        pianoVoicePlayer.volume = 1.0
        pianoVoicePlayer.prepareToPlay()
        pianoVoicePlayer.play()
        
        let nowX = musicalNote.list[index].x
        effect.position = CGPoint(x: nowX + itemWidth / 2, y: 80)
        effect.zPosition = 3
        effect.alpha = 1
        currentSquare[index].fillColor = #colorLiteral(red: 0.8862745098, green: 0.8823529412, blue: 0.8941176471, alpha: 1)
        labelForSquare[index].fontColor = .black
    }
    
    func addBlock(string:String,time:Double){
        block = musicalNote.customNote(noteTexture: returnTextureForNote(note: string), height: CGFloat(time) * nodeSpeed)
        currentBlocks.append(block)
        addChild(block)
        let minY = 80 - block.size.height
        let duration = (screen_height - minY) / nodeSpeed
        let move = SKAction.moveTo(y: minY, duration: TimeInterval(duration))
        block.run(move,withKey: "move")
    }
    
    //检测游戏效果
    func checkForEffect(nBlock:SKSpriteNode,curPitch:String){
        let startY = CGFloat(80)
        let endY = 80 - nBlock.size.height
        
        if ((nBlock.position.y <= startY)&&(effect.alpha==0)&&(curPitch==nBlock.name)){
            let nowX = nBlock.position.x
            
            effect.position = CGPoint(x: nowX + itemWidth / 2, y: 80)
            effect.zPosition = 3
            effect.alpha = 1
            isThreeHit += 1
            tipSuccessToShow()
        }
        
        if curPitch != nBlock.name {
            effect.alpha = 0
            if curPitch != "None" {
                tipFailToShow()
            }
        }
        
        if nBlock.position.y <= endY {
            effect.alpha = 0
            nBlock.removeFromParent()
            currentBlocks.remove(at: 0)
        }
    }
    
    func tipSuccessToShow(){
        let modeThree = isThreeHit % 3
        if(modeThree == 0 && isThreeHit != 0){
            perfectTip.alpha = 1
            goodTip.alpha = 0
            missTip.alpha = 0
        }else{
            goodTip.alpha = 1
            perfectTip.alpha = 0
            missTip.alpha = 0
        }
    }
    
    func tipFailToShow(){
        perfectTip.alpha = 0
        goodTip.alpha = 0
        missTip.alpha = 1
    }
    
    //对UI进行初始化设置
    func setupUI(to view: SKView){
        let background = SKSpriteNode(color: #colorLiteral(red: 0.8196078431, green: 0.7607843137, blue: 0.8274509804, alpha: 1), size: CGSize(width: screen_width, height: screen_height - 100))
        background.anchorPoint = CGPoint.zero
        background.position = CGPoint.zero
        addChild(background)
        
        
        let track = SKSpriteNode(color: #colorLiteral(red: 0.7843137255, green: 0.6784313725, blue: 0.768627451, alpha: 1), size: CGSize(width: screen_width - 160, height: screen_height - 100))
        track.anchorPoint = CGPoint.zero
        track.position = CGPoint(x: 80, y: 0)
        addChild(track)
        
        
        missTip = SKSpriteNode(imageNamed: "miss.png")
        missTip.size = CGSize(width: 220, height: 220)
        missTip.position = CGPoint(x: screen_width / 2, y: screen_height - 100 - 110)
        missTip.alpha = 0
        missTip.zPosition = 5
        addChild(missTip)
        
        goodTip = SKSpriteNode(imageNamed: "good.png")
        goodTip.size = CGSize(width: 220, height: 220)
        goodTip.position = CGPoint(x: screen_width / 2, y: screen_height - 100 - 110)
        goodTip.alpha = 0
        goodTip.zPosition = 5
        addChild(goodTip)
        
        perfectTip = SKSpriteNode(imageNamed: "perfect.png")
        perfectTip.size = CGSize(width: 220, height: 220)
        perfectTip.position = CGPoint(x: screen_width / 2, y: screen_height - 100 - 110)
        perfectTip.alpha = 0
        perfectTip.zPosition = 5
        addChild(perfectTip)
        
        
        squareOne.path = CGPath(roundedRect: CGRect(x: 80, y: 0, width: itemWidth, height: 80), cornerWidth: 15, cornerHeight: 10, transform: nil)
        squareTwo.path = CGPath(roundedRect: CGRect(x: 80+itemWidth, y: 0, width: itemWidth, height: 80), cornerWidth: 15, cornerHeight: 10, transform: nil)
        squareThree.path = CGPath(roundedRect: CGRect(x: 80+itemWidth*2, y: 0, width: itemWidth, height: 80), cornerWidth: 15, cornerHeight: 10, transform: nil)
        squareFour.path = CGPath(roundedRect: CGRect(x: 80+itemWidth*3, y: 0, width: itemWidth, height: 80), cornerWidth: 15, cornerHeight: 10, transform: nil)
        squareFive.path = CGPath(roundedRect: CGRect(x: 80+itemWidth*4, y: 0, width: itemWidth, height: 80), cornerWidth: 15, cornerHeight: 10, transform: nil)
        squareSix.path = CGPath(roundedRect: CGRect(x: 80+itemWidth*5, y: 0, width: itemWidth, height: 80), cornerWidth: 15, cornerHeight: 10, transform: nil)
        squareSeven.path = CGPath(roundedRect: CGRect(x: 80+itemWidth*6, y: 0, width: itemWidth, height: 80), cornerWidth: 15, cornerHeight: 10, transform: nil)
        squareOne.fillColor = #colorLiteral(red: 0.4549019608, green: 0.4588235294, blue: 0.6078431373, alpha: 1)
        squareTwo.fillColor = #colorLiteral(red: 0.4549019608, green: 0.4588235294, blue: 0.6078431373, alpha: 1)
        squareThree.fillColor = #colorLiteral(red: 0.4549019608, green: 0.4588235294, blue: 0.6078431373, alpha: 1)
        squareFour.fillColor = #colorLiteral(red: 0.4549019608, green: 0.4588235294, blue: 0.6078431373, alpha: 1)
        squareFive.fillColor = #colorLiteral(red: 0.4549019608, green: 0.4588235294, blue: 0.6078431373, alpha: 1)
        squareSix.fillColor = #colorLiteral(red: 0.4549019608, green: 0.4588235294, blue: 0.6078431373, alpha: 1)
        squareSeven.fillColor = #colorLiteral(red: 0.4549019608, green: 0.4588235294, blue: 0.6078431373, alpha: 1)
        squareOne.glowWidth = 2
        squareTwo.glowWidth = 2
        squareThree.glowWidth = 2
        squareFour.glowWidth = 2
        squareFive.glowWidth = 2
        squareSix.glowWidth = 2
        squareSeven.glowWidth = 2
        
        
        addChild(squareOne)
        addChild(squareTwo)
        addChild(squareThree)
        addChild(squareFour)
        addChild(squareFive)
        addChild(squareSix)
        addChild(squareSeven)
        
        squareLower.path = CGPath(roundedRect: CGRect(x: 50, y: 0, width: 30, height: 80), cornerWidth: 10, cornerHeight: 10, transform: nil)
        squareLower.fillColor = #colorLiteral(red: 0.8862745098, green: 0.8823529412, blue: 0.8941176471, alpha: 1)
        squareLower.glowWidth = 2
        squareLower.alpha = 0
        addChild(squareLower)
        
        squareHigher.path = CGPath(roundedRect: CGRect(x: 80+itemWidth*7, y: 0, width: 30, height: 80), cornerWidth: 10, cornerHeight: 10, transform: nil)
        squareHigher.fillColor = #colorLiteral(red: 0.8862745098, green: 0.8823529412, blue: 0.8941176471, alpha: 1)
        squareHigher.glowWidth = 2
        squareHigher.alpha = 0
        addChild(squareHigher)
        
        currentSquare = [squareOne,squareTwo,squareThree,squareFour,squareFive,squareSix,squareSeven]
        
        squareOne.zPosition = 1
        squareTwo.zPosition = 1
        squareThree.zPosition = 1
        squareFour.zPosition = 1
        squareFive.zPosition = 1
        squareSix.zPosition = 1
        squareSeven.zPosition = 1
        
        labelForOne = SKLabelNode(text: "Do")
        labelForTwo = SKLabelNode(text: "Re")
        labelForThree = SKLabelNode(text: "Mi")
        labelForFour = SKLabelNode(text: "Fa")
        labelForFive = SKLabelNode(text: "So")
        labelForSix = SKLabelNode(text: "La")
        labelForSeven = SKLabelNode(text: "Si")
        
        labelForSquare = [labelForOne,labelForTwo,labelForThree,labelForFour,labelForFive,labelForSix,labelForSeven]
        
        for i in 0..<7{
            labelForSquare[i].fontColor = #colorLiteral(red: 0.8823529412, green: 0.8862745098, blue: 0.8941176471, alpha: 1)
            let xn = CGFloat(80) + itemWidth * CGFloat(i) + itemWidth / CGFloat(2)
            labelForSquare[i].fontName = "PingFangSC-Semibold"
            labelForSquare[i].position = CGPoint(x: xn, y: 30)
            labelForSquare[i].zPosition = 2
        }
        
        squareOne.addChild(labelForOne)
        squareTwo.addChild(labelForTwo)
        squareThree.addChild(labelForThree)
        squareFour.addChild(labelForFour)
        squareFive.addChild(labelForFive)
        squareSix.addChild(labelForSix)
        squareSeven.addChild(labelForSeven)
        
        effect = SKEmitterNode(fileNamed: "SparkAnimation")!
        effect.alpha = 0
        effect.zPosition = 3
        addChild(effect)
    }
    
}
