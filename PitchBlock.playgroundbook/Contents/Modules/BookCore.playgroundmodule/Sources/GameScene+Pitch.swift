//
//  GameScene+Pitch.swift
//  MusicGameTest
//
//  Created by ZouYa on 2021/3/24.
//

import UIKit
import SpriteKit

extension GameScene {
    
    //读json文件转化音符
    func readNoteFromJson(file:String)->[NoteData]{
        if let path = Bundle.main.path(forResource: file, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let jsonResult = json as? Dictionary<String, Any>,let song = jsonResult["song"] as? [Any]{
                    var note:[NoteData] = []
                    for index in 0..<song.count {
                        let cur = NoteData.init(json: song[index] as! [String:Any])
                        note.append(cur!)
                    }
                    return note
                }
              } catch {
                   print("error")
              }
        }
        return []
    }
    
    //读json文件转化间隔时间
    func readGapTimeFromJson(file:String)->[Double]{
        if let path = Bundle.main.path(forResource: file, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let jsonResult = json as? Dictionary<String, Any>,let gapTime = jsonResult["gap"] as? [Any]{
                    var gap:[Double] = []
                    for index in 0..<gapTime.count {
                        let cur = gapTime[index] as! [String:Any]
                        let curTime = Double(cur["time"] as! String)!
                        gap.append(curTime)
                    }
                    return gap
                }
              } catch {
                   print("error")
              }
        }
        return []
    }
    
    //把音高转换成对应的音符
    func convertPitchToNote(pitch:CGFloat)->String{
        switch pitch {
        case 70..<71.5:
            return "Si"//71
        case 68..<70:
            return "La"//69
        case 66..<68:
            return "So"//67
        case 64.5..<66:
            return "Fa"//65
        case 63..<64.5:
            return "Mi"//64
        case 61..<63:
            return "Re"//62
        case 59.5..<61:
            return "Do"//60
        default:
            return "None"
        }
    }
    
    //把音高转化成index
    func returnIndexForPitch(pitch:String)->Int{
        switch pitch {
            case "Do":
                return 0
            case "Re":
                return 1
            case "Mi":
                return 2
            case "Fa":
                return 3
            case "So":
                return 4
            case "La":
                return 5
            case "Si":
                return 6
            default:
                return -1
        }
    }

    
    func returnTextureForNote(note:String)->MusicalNoteTexture{
        switch note {
        case "Do":
            return MusicalNoteTexture.Do
        case "Re":
            return MusicalNoteTexture.Re
        case "Mi":
            return MusicalNoteTexture.Mi
        case "Fa":
            return MusicalNoteTexture.Fa
        case "So":
            return MusicalNoteTexture.So
        case "La":
            return MusicalNoteTexture.La
        case "Si":
            return MusicalNoteTexture.Si
        default:
            return MusicalNoteTexture.Do
        }
    }
    
}
