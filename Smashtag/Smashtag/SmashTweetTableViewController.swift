//
//  SmashTweetTableViewController.swift
//  Smashtag
//
//  Created by Tatiana Kornilova on 5/29/17.
//  Copyright © 2017 Stanford University. All rights reserved.
//

import UIKit
import Twitter
import CoreData

class SmashTweetTableViewController: TweetTableViewController {
    var container: NSPersistentContainer? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    override func insertTweets(_ newTweets: [Twitter.Tweet]){
        super.insertTweets(newTweets)
        if searchText != nil {
        updateDatabase(with: newTweets)
        }
    }
    
    private func updateDatabase(with tweets: [Twitter.Tweet]){
            container?.performBackgroundTask{ [weak self] (context) in
  // one by one
 /*           for twitterInfo in tweets {
                //add tweet
               _ = try? Tweet.findTweetAndCheckMentions(for: twitterInfo,
                                                         with: (self?.searchText)!,
                                                         in: context)
            }
 */
// all more effective
                try? Tweet.newTweets(for: tweets,
                                     with: (self?.searchText)!,
                                     in: context)
    
            try? context.save()
            self?.printDatabaseStatistics()
        }
    }
    
    private func printDatabaseStatistics(){
        //on the main queue context
        if let context = container?.viewContext{
            context.perform{
                if let tweetCount = ( try? context.fetch( Tweet.fetchRequest()
                                                    as NSFetchRequest<Tweet> ))?.count{
                    print("\(tweetCount) tweets")
                }
                if let mentionsCount =  try? context.count(for: Mention.fetchRequest()){
                    print ("\(mentionsCount) mentions")
                }
            }
        }
    }
 }
