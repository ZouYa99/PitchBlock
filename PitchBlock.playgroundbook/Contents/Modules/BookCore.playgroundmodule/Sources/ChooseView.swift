//
//  ChooseView.swift
//  MusicGameTest
//
//  Created by ZouYa on 2021/4/18.
//

import UIKit

public class ChooseView:UIView{
    
    var showMode = UIButton()
    var freeMode = UIButton()
    var practiceMode = UIButton()
    var songMode = UIButton()
    
    var showLabel = UILabel()
    var freeLabel = UILabel()
    var practiceLabel = UILabel()
    var songLabel = UILabel()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupViewUI()
        
    }
    
    func setupViewUI(){
        self.backgroundColor = #colorLiteral(red: 0.6549019608, green: 0.6588235294, blue: 0.7411764706, alpha: 1)
        
        showLabel.text = "Demo"
        freeLabel.text = "FreeStyle"
        practiceLabel.text = "Vocal\nPractice"
        practiceLabel.numberOfLines = 2
        songLabel.text = "Sing a song"
        
        showLabel.textColor = .white
        freeLabel.textColor = .white
        practiceLabel.textColor = .white
        songLabel.textColor = .white
        
        addSubview(showMode)
        showMode.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            showMode.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 26),
            showMode.topAnchor.constraint(equalTo: self.topAnchor, constant: 30),
            showMode.widthAnchor.constraint(equalToConstant: 60),
            showMode.heightAnchor.constraint(equalToConstant: 60)
        ])
        showMode.setImage(UIImage(named: "piano.png"), for: .normal)
        
        addSubview(showLabel)
        showLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            showLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 30),
            showLabel.topAnchor.constraint(equalTo: showMode.bottomAnchor, constant: 25)
        ])
        showLabel.textAlignment = .center
        showLabel.backgroundColor = #colorLiteral(red: 0.6549019608, green: 0.6588235294, blue: 0.7411764706, alpha: 1)
        showLabel.sizeToFit()
        
        addSubview(freeMode)
        freeMode.translatesAutoresizingMaskIntoConstraints  = false
        NSLayoutConstraint.activate([
            freeMode.leadingAnchor.constraint(equalTo: showMode.trailingAnchor, constant: 25),
            freeMode.topAnchor.constraint(equalTo: self.topAnchor, constant: 30),
            freeMode.widthAnchor.constraint(equalToConstant: 60),
            freeMode.heightAnchor.constraint(equalToConstant: 60)
        ])
        freeMode.setImage(UIImage(named: "free.png"), for: .normal)
        
        addSubview(freeLabel)
        freeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            freeLabel.leadingAnchor.constraint(equalTo: showMode.trailingAnchor, constant: 23),
            freeLabel.topAnchor.constraint(equalTo: freeMode.bottomAnchor, constant: 25)
        ])
        freeLabel.textAlignment = .center
        freeLabel.backgroundColor = #colorLiteral(red: 0.6549019608, green: 0.6588235294, blue: 0.7411764706, alpha: 1)
        freeLabel.sizeToFit()
        
        addSubview(practiceMode)
        practiceMode.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            practiceMode.leadingAnchor.constraint(equalTo: freeMode.trailingAnchor, constant: 25),
            practiceMode.topAnchor.constraint(equalTo: self.topAnchor, constant: 30),
            practiceMode.widthAnchor.constraint(equalToConstant: 60),
            practiceMode.heightAnchor.constraint(equalToConstant: 60)
        ])
        practiceMode.setImage(UIImage(named: "practice.png"), for: .normal)
        
        addSubview(practiceLabel)
        practiceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            practiceLabel.leadingAnchor.constraint(equalTo: freeMode.trailingAnchor, constant: 26),
            practiceLabel.topAnchor.constraint(equalTo: practiceMode.bottomAnchor, constant: 20)
        ])
        practiceLabel.textAlignment = .center
        practiceLabel.backgroundColor = #colorLiteral(red: 0.6549019608, green: 0.6588235294, blue: 0.7411764706, alpha: 1)
        practiceLabel.sizeToFit()

        
        addSubview(songMode)
        songMode.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            songMode.leadingAnchor.constraint(equalTo: practiceMode.trailingAnchor, constant: 27),
            songMode.topAnchor.constraint(equalTo: self.topAnchor, constant: 30),
            songMode.widthAnchor.constraint(equalToConstant: 60),
            songMode.heightAnchor.constraint(equalToConstant: 60)
        ])
        songMode.setImage(UIImage(named: "sing.png"), for: .normal)
        
        addSubview(songLabel)
        songLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            songLabel.leadingAnchor.constraint(equalTo: practiceMode.trailingAnchor, constant: 23),
            songLabel.topAnchor.constraint(equalTo: songMode.bottomAnchor, constant: 25)
        ])
        songLabel.textAlignment = .center
        songLabel.backgroundColor = #colorLiteral(red: 0.6549019608, green: 0.6588235294, blue: 0.7411764706, alpha: 1)
        songLabel.sizeToFit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
