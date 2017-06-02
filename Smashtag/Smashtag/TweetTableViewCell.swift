//
//  TweetTableViewCell.swift
//  Smashtag
//
//  Created by CS193p Instructor on 2/8/17.
//  Copyright © 2017 Stanford University. All rights reserved.
//

import UIKit
import Twitter

class TweetTableViewCell: UITableViewCell
{
    // outlets к UI компонентам в нашей Custom UITableViewCell
    @IBOutlet weak var tweetProfileImageView: UIImageView!
    @IBOutlet weak var tweetCreatedLabel: UILabel!
    @IBOutlet weak var tweetUserLabel: UILabel!
    @IBOutlet weak var tweetTextLabel: UILabel!

    // public API subclass этого класса UITableViewCell
    // каждая строка в таблице имеет собственный экземпляр этого класса
    // и у каждого экземпляра будет собственный tweet для показа
    // устанавливается как переменная var
    var tweet: Twitter.Tweet? { didSet { updateUI() } }
    
    // как только наш public API tweet устанавливается
    // мы просто обновляем наши outlets, используя этот метод
    private func updateUI() {
        
        tweetTextLabel?.attributedText  = setTextLabel(tweet)
        tweetUserLabel?.text = tweet?.user.description
        setProfileImageView(tweet) // tweetProfileImageView обновляем асинхронно
        
        if let created = tweet?.created {
            let formatter = DateFormatter()
            if Date().timeIntervalSince(created) > 24*60*60 {
                formatter.dateStyle = .short
            } else {
                formatter.timeStyle = .short
            }
            tweetCreatedLabel?.text = formatter.string(from: created)
        } else {
            tweetCreatedLabel?.text = nil
        }
    }
    
    private func setProfileImageView(_ tweet: Twitter.Tweet?) {
        tweetProfileImageView?.image = nil
        guard let tweet = tweet,
            let profileImageURL = tweet.user.profileImageURL else {return}
        
        // MARK: Выбираем данные за пределами main queue
        DispatchQueue.global(qos: .userInitiated).async {[weak self]  in
            
            let contentsOfURL = try? Data(contentsOf: profileImageURL)
            if profileImageURL == tweet.user.profileImageURL,
                let imageData = contentsOfURL  {
                
                // MARK: UI -> Возвращаемся на main queue
                DispatchQueue.main.async {
                    self?.tweetProfileImageView?.image = UIImage(data: imageData)
                    
                }
            }
        }
    }


    private func setTextLabel(_ tweet: Twitter.Tweet?) -> NSMutableAttributedString {
        guard let tweet = tweet else {return NSMutableAttributedString(string: "")}
        var tweetText:String = tweet.text
        for _ in tweet.media {tweetText += " 📷"}
        
        let attributedText = NSMutableAttributedString(string: tweetText)
        
        attributedText.setMensionsColor(tweet.hashtags, color: Palette.hashtagColor)
        attributedText.setMensionsColor(tweet.urls, color: Palette.urlColor)
        attributedText.setMensionsColor(tweet.userMentions, color: Palette.userColor)
        
        return attributedText
    }
    
    struct Palette {
        static let hashtagColor = UIColor.purple
        static let urlColor = UIColor.blue
        static let userColor = UIColor.orange
    }
}

// MARK: - Расширение

private extension NSMutableAttributedString {
    func setMensionsColor(_ mensions: [Twitter.Mention], color: UIColor) {
        for mension in mensions {
            addAttribute(NSForegroundColorAttributeName, value: color,
                                                         range: mension.nsrange)
        }
    }
}
