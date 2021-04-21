//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  A source file which is part of the auxiliary module named "BookCore".
//  Provides the implementation of the "always-on" live view.
//

import UIKit
import PlaygroundSupport
import SpriteKit
import AVFoundation

let screen_width = UIScreen.main.bounds.width / 2
let screen_height = UIScreen.main.bounds.height
let itemWidth = (screen_width - 160)/7

@objc(BookCore_LiveViewController)
public class LiveViewController: UIViewController,AVAudioRecorderDelegate,AVAudioPlayerDelegate, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer {
    /*
    public func liveViewMessageConnectionOpened() {
        // Implement this method to be notified when the live view message connection is opened.
        // The connection will be opened when the process running Contents.swift starts running and listening for messages.
    }
    */

    /*
    public func liveViewMessageConnectionClosed() {
        // Implement this method to be notified when the live view message connection is closed.
        // The connection will be closed when the process running Contents.swift exits and is no longer listening for messages.
        // This happens when the user's code naturally finishes running, if the user presses Stop, or if there is a crash.
    }
    */
    
    var sceneView = SKView()
    var scene = GameScene()
    
    var chooseView = ChooseView()
    var constraintOfChooseView:NSLayoutConstraint!
    var exitButton = UIButton()
    
    var surprise = UIImageView()
    
    var pitchService = RealPitchService()
    var isRecording = false
    
    var mode:String = ""
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0.8196078431, green: 0.7607843137, blue: 0.8274509804, alpha: 1)
        view.frame = CGRect(x: 0, y: 0, width: screen_width, height: screen_height)
        sceneView.frame = CGRect(x: 0, y: 0, width: screen_width, height: screen_height - 100)
        scene.size = CGSize(width: screen_width, height: screen_height - 100)
        sceneView.presentScene(scene)
        
        self.view = view
        view.addSubview(sceneView)
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateMusicNotationView(notification:)), name: NSNotification.Name("realPitch"), object: nil)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "GameOver"), object: nil, queue: .main) { [self] (notification) in
            stopRecorder()
            isRecording = false
            DispatchQueue.main.async {
                self.scene.finishThisGame()
            }
            reshowView()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "ShowEffectEnd"), object: nil, queue: .main) { [self] (notification) in
            reshowView()
        }
    }
    
    @objc func updateMusicNotationView(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let pitchData = userInfo["pitch"] as! Float
        let Pitch = CGFloat(pitchData)
        
        self.scene.pitchData = Pitch
    }
    
    func setupUI(){
        
        view.addSubview(chooseView)
        chooseView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chooseView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: screen_width / 2 - 188),
            chooseView.heightAnchor.constraint(equalToConstant: 160),
            chooseView.widthAnchor.constraint(equalToConstant: 375)
        ])
        constraintOfChooseView = chooseView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: screen_height / 2 - 80)
        constraintOfChooseView.isActive = true
        chooseView.layer.masksToBounds = true
        chooseView.layer.cornerRadius = 20
        chooseView.showMode.addTarget(self, action: #selector(clickShowMode), for: .touchUpInside)
        chooseView.freeMode.addTarget(self, action: #selector(clickFreeMode), for: .touchUpInside)
        chooseView.practiceMode.addTarget(self, action: #selector(clickPracticeMode), for: .touchUpInside)
        chooseView.songMode.addTarget(self, action: #selector(clickSingMode), for: .touchUpInside)
        
        view.addSubview(exitButton)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            exitButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            exitButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30),
            exitButton.widthAnchor.constraint(equalToConstant: 40),
            exitButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        exitButton.setImage(UIImage(named: "exit.png"), for: .normal)
        exitButton.addTarget(self, action: #selector(clickExit), for: .touchUpInside)
        exitButton.isEnabled = false
        
        view.addSubview(surprise)
        surprise.image = UIImage(named: "surprise.png")
        surprise.frame = CGRect(x: screen_width * 3 / 2 - 150, y: screen_height / 2 - 150, width: 300, height: 300)
    }
    
    @objc func clickExit(){
        if mode == "show" {
            scene.removeShowBlock()
            reshowView()
        }else if mode == "free"{
            stopRecorder()
            isRecording = false
            reshowView()
            DispatchQueue.main.async {
                self.scene.finishThisGame()
            }
        }else{
            scene.removeBlockProduce()
            stopRecorder()
            isRecording = false
            reshowView()
            DispatchQueue.main.async {
                self.scene.finishThisGame()
            }
        }
    }
    
    
    @objc func clickShowMode(){
        resignView()
        scene.showBlockAndEffect()
        mode = "show"
    }
    
    @objc func clickFreeMode(){
        resignView()
        pitchService.startRecord()
        isRecording = true
        mode = "free"
    }
    
    @objc func clickPracticeMode(){
        resignView()
        pitchService.startRecord()
        isRecording = true
        scene.produceNewBlockFromJson(mode: "Practice")
        mode = "practice"
    }
    
    @objc func clickSingMode(){
        resignView()
        pitchService.startRecord()
        isRecording = true
        scene.produceNewBlockFromJson(mode: "Sing")
        mode = "sing"
    }
    
    func reshowView(){
        exitButton.isEnabled = false
        constraintOfChooseView.constant = screen_height / 2 - 80
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func resignView(){
        exitButton.isEnabled = true
        constraintOfChooseView.constant = -400
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func stopRecorder(){
        pitchService.stopRecord()
    }
    
    
    public override func viewDidDisappear(_ animated: Bool) {
        pitchService.stopRecord()
    }

    public func receive(_ message: PlaygroundValue) {
        // Implement this method to receive messages sent from the process running Contents.swift.
        // This method is *required* by the PlaygroundLiveViewMessageHandler protocol.
        // Use this method to decode any messages sent as PlaygroundValue values and respond accordingly.
    }
}
