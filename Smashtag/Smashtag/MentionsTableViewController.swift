//
//  MentionsTableViewController.swift
//  Smashtag
//
//  Created by Tatiana Kornilova on 7/6/15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit
import Twitter
import SafariServices

class MentionsTableViewController: UITableViewController {

    // MARK: - Public API

    var tweet: Twitter.Tweet? {
        
        didSet {
            guard let tweet = tweet else { return }
            title = tweet.user.screenName
            mentionSections = initMensionSections(from: tweet)
            tableView.reloadData()
        }
    }
    
    // MARK: - Внутренняя структура данных
    
    private var mentionSections = [MentionSection]() // массив секций
  
    private struct MentionSection {  // секция
        var type: String
        var mentions: [MentionItem]
    }
    
    private enum MentionItem {     // строка
        case keyword(String)
        case image(URL, Double)
        
    }
    
    private func initMensionSections(from tweet:Twitter.Tweet)-> [MentionSection]{
        var mentionSections = [MentionSection]()
        
        if  tweet.media.count > 0 {
            mentionSections.append(MentionSection(type: "Images",
                mentions: tweet.media.map{ MentionItem.image($0.url, $0.aspectRatio)}))
        }
        if tweet.urls.count > 0 {
            mentionSections.append(MentionSection(type: "URLs",
                mentions: tweet.urls.map{ MentionItem.keyword($0.keyword)}))
        }
        if tweet.hashtags.count > 0 {
            mentionSections.append(MentionSection(type: "Hashtags",
                mentions: tweet.hashtags.map{ MentionItem.keyword($0.keyword)}))
        }
        var userItems = [MentionItem]()
        
        //------- Extra Credit 1 -------------
        userItems += [MentionItem.keyword("@" + tweet.user.screenName )]
        //------------------------------------------------
       
        if tweet.userMentions.count > 0 {
            userItems += tweet.userMentions.map { MentionItem.keyword($0.keyword) }
        }
        if userItems.count > 0 {
            mentionSections.append(MentionSection(type: "Users", mentions: userItems))
        }
        
        return mentionSections
    }
    
       // MARK: - UITableViewControllerDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return mentionSections.count
    }
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return mentionSections[section].mentions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt
                            indexPath: IndexPath) -> UITableViewCell {
        
        let mention = mentionSections[indexPath.section].mentions[indexPath.row]
        
        switch mention {
        case .keyword(let keyword):
            let cell = tableView.dequeueReusableCell(
                       withIdentifier: Storyboard.KeywordCell,for: indexPath)
            cell.textLabel?.text = keyword
            return cell
            
        case .image(let url, _):
            let cell = tableView.dequeueReusableCell(
                       withIdentifier: Storyboard.ImageCell, for: indexPath)
            if let imageCell = cell as? ImageTableViewCell {
              imageCell.imageUrl = url
            }
             return cell
        }
    }
    
    override func tableView(_ tableView: UITableView,
                      heightForRowAt indexPath: IndexPath) -> CGFloat {
                            
        let mention = mentionSections[indexPath.section].mentions[indexPath.row]
        switch mention {
        case .image(_, let ratio):
            return tableView.bounds.size.width / CGFloat(ratio)
        default:
            return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView,
                                  titleForHeaderInSection section: Int) -> String? {
        return mentionSections[section].type
    }
    
    
    // MARK: - Navitation
    
    @IBAction private func toRootViewController(_ sender: UIBarButtonItem) {
        
       _ = navigationController?.popToRootViewController(animated: true)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String,
                                     sender: Any?) -> Bool {
        if identifier == Storyboard.KeywordSegue {
            if let cell = sender as? UITableViewCell,
                let indexPath =  tableView.indexPath(for: cell),
                mentionSections[indexPath.section].type == "URLs" {
                
             /*  if let urlString = cell.textLabel?.text,
                    let url = URL(string:urlString) {
                    
                    let safariVC = SFSafariViewController(url: url)
                     present(safariVC, animated: true, completion: nil)
                    
                    //   if #available(iOS 10.0, *) {
                    //       UIApplication.shared.open(url, options: [:],
                    //                            completionHandler: nil)
                    //   } else {
                    //       UIApplication.shared.openURL(url)
                    //   }
                } 
            */
                performSegue(withIdentifier: Storyboard.WebSegue, sender: sender)
                return false
            }
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    
    private struct Storyboard {
        static let KeywordCell = "Keyword Cell"
        static let ImageCell = "Image Cell"
        
        static let KeywordSegue = "From Keyword"
        static let ImageSegue = "Show Image"
        static let WebSegue = "Show URL"
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            
            if identifier == Storyboard.KeywordSegue {
                if let ttvc = segue.destination as? TweetTableViewController,
                    let cell = sender as? UITableViewCell,
                    var text = cell.textLabel?.text {
                    if text.hasPrefix("@") {text += " OR from:" + text} //Extra Credit 2
                    ttvc.searchText = text
                }
                
            } else if identifier == Storyboard.ImageSegue {
                if let ivc = segue.destination as? ImageViewController,
                    let cell = sender as? ImageTableViewCell {
                    
                    ivc.imageURL = cell.imageUrl
                    ivc.title = title
                    
                }
            } else if identifier == Storyboard.WebSegue {
                if let wvc = segue.destination as? WebViewController {
                    if let cell = sender as? UITableViewCell {
                        if let url = cell.textLabel?.text {
                            
                            wvc.URL = URL(string: url)
                        }
                    }
                }
            }
        }
    }
}
