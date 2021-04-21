//
//  MusicalNote.swift
//  MusicGameTest
//
//  Created by ZouYa on 2021/3/6.
//

import UIKit
import SpriteKit

public class MusicalNote {
    let list = [
        MusicalNoteTexture.Do,
        MusicalNoteTexture.Re,
        MusicalNoteTexture.Mi,
        MusicalNoteTexture.Fa,
        MusicalNoteTexture.So,
        MusicalNoteTexture.La,
        MusicalNoteTexture.Si
    ]
    
    public func customNote(noteTexture:MusicalNoteTexture,height:CGFloat)->SKSpriteNode{
        
        let currentColor = noteTexture.color
        let blockSize = CGSize(width: itemWidth, height: height)
        let block = SKSpriteNode(color: currentColor, size: blockSize)
        block.anchorPoint = CGPoint.zero
        block.position = CGPoint(x: noteTexture.x, y: screen_height)
        block.name = noteTexture.name
        
        let label = SKLabelNode(text: noteTexture.name)
        label.fontColor = .white
        label.fontName = "PingFangSC-Semibold"
        label.position = CGPoint(x: blockSize.width / 2, y: blockSize.height / 2 - 5)
        label.fontSize = 20
        block.addChild(label)
        
        return block
    }
    
    public func SingleNote(Number:Int)->SKSpriteNode{
        let current = list[Number]
        let height = CGFloat(0.4 * 120)
        let currentColor = current.color
        
        let noteSize = CGSize(width: itemWidth, height: height)
        let note = SKSpriteNode(color: currentColor, size: noteSize)
        note.anchorPoint = CGPoint.zero
        note.position = CGPoint(x: current.x, y: screen_height)
        note.name = current.name
        
        let label = SKLabelNode(text: current.name)
        label.fontColor = .white
        label.fontName = "PingFangSC-Semibold"
        label.fontSize = 20
        label.position = CGPoint(x: noteSize.width / 2, y: noteSize.height / 2 - 5)
        note.addChild(label)
        
        return note
    }
}

public enum MusicalNoteTexture : String , CaseIterable {
    case Do = "Do"
    case Re = "Re"
    case Mi = "Mi"
    case Fa = "Fa"
    case So = "So"
    case La = "La"
    case Si = "Si"
    
    var name:String{
        rawValue
    }
    
    var color : UIColor{
        switch self {
        case .Do:  return #colorLiteral(red: 0.9294117647, green: 0.3333333333, blue: 0.4156862745, alpha: 1)
        case .Re:  return #colorLiteral(red: 0.9490196078, green: 0.5568627451, blue: 0.0862745098, alpha: 1)
        case .Mi:  return #colorLiteral(red: 0.9764705882, green: 0.8274509804, blue: 0.4039215686, alpha: 1)
        case .Fa:  return #colorLiteral(red: 0.5490196078, green: 0.7607843137, blue: 0.4117647059, alpha: 1)
        case .So:  return #colorLiteral(red: 0, green: 0.5450980392, blue: 0.5450980392, alpha: 1)
        case .La:  return #colorLiteral(red: 0.3803921569, green: 0.6039215686, blue: 0.7647058824, alpha: 1)
        case .Si:  return #colorLiteral(red: 0.6784313725, green: 0.3960784314, blue: 0.5960784314, alpha: 1)
        
        }
    }
    
    var x : CGFloat{
        switch self {
        case .Do:  return CGFloat(80)
        case .Re:  return 80+itemWidth
        case .Mi:  return 80+itemWidth*2
        case .Fa:  return 80+itemWidth*3
        case .So:  return 80+itemWidth*4
        case .La:  return 80+itemWidth*5
        case .Si:  return 80+itemWidth*6
        
        }
    }
}

public struct NoteData{
    var note:String
    var continuanceTime:Double
    
    init?(json:[String:Any]) {
        guard let note = json["note"] as? String else {
            return nil
        }
        self.note = note
        self.continuanceTime = Double(json["continuance"] as! String)!
    }
}
