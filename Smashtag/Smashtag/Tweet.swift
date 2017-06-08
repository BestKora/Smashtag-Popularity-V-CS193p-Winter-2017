//
//  Tweet.swift
//  Smashtag
//
//  Created by Tatiana Kornilova on 5/31/17.
//  Copyright © 2017 Stanford University. All rights reserved.
//

import UIKit
import CoreData
import Twitter

class Tweet: NSManagedObject {
    class func findOrCreateTweet(matching twitterInfo: Twitter.Tweet,
                                 in context: NSManagedObjectContext) throws -> Tweet
    {
        let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
        request.predicate = NSPredicate(format: "unique = %@", twitterInfo.identifier)
       
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1,
                       "Tweet.findOrCreateTweet -- database inconsistency")
                return matches[0]
            } else {
                let tweet = Tweet(context: context)
                tweet.unique = twitterInfo.identifier
                tweet.text = twitterInfo.text
                tweet.created = twitterInfo.created as NSDate
                return tweet
            }
            
        } catch {
            throw error
        }
      
    }
    
    class func findTweetAndCheckMentions(for twitterInfo: Twitter.Tweet,
                                         with searchTerm: String,
                                    in context: NSManagedObjectContext) throws -> Tweet
    {
        do {
            let tweet = try findOrCreateTweet(matching: twitterInfo,in: context)
            let hashtags = twitterInfo.hashtags
            for hashtag in hashtags{
                _ = try? Mention.checkMention(for: tweet,
                                                     withKeyword: hashtag.keyword,
                                                     andType: "Hashtags",
                                                     andTerm: searchTerm,
                                                     in: context)
            }
            let users = twitterInfo.userMentions
            for user in users {
                _ = try? Mention.checkMention(for: tweet,
                                                     withKeyword: user.keyword,
                                                     andType: "Users",
                                                     andTerm: searchTerm,
                                                     in: context)
            }
            // Для пользователя твита
            let userScreenName = "@" + twitterInfo.user.screenName
            _ = try? Mention.checkMention(for: tweet,
                                                 withKeyword: userScreenName,
                                                 andType: "Users",
                                                 andTerm: searchTerm,
                                                 in: context)
            
            return tweet
            
            
        } catch {
            throw error
        }
    }
    
    class func newTweets( for twitterInfos: [Twitter.Tweet],
                          with searchTerm: String,
                          in context: NSManagedObjectContext) throws
    {
        let newTweetsIdentifiers = twitterInfos.map {$0.identifier}
        var newsSet = Set (newTweetsIdentifiers)
        
        let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
        request.predicate = NSPredicate(
            format: "any mentions.searchTerm contains[c] %@ and unique IN %@",
            searchTerm, newsSet )
        
        do {
            let tweets = try context.fetch(request)
            let oldTweetsUniques = tweets.flatMap({ $0.unique})
            let oldsSet = Set (oldTweetsUniques)
            
            newsSet.subtract(oldsSet)
            print ("-----------кол-во новых элементов \(newsSet.count)-----")
            
            for unique in newsSet{
                if let index = twitterInfos.index(where: {$0.identifier == unique}){
                    _ = try? Tweet.findTweetAndCheckMentions(for: twitterInfos[index],
                                                             with:searchTerm,
                                                             in: context)
                    
                }
            }
            
        } catch {
            throw error
        }
    }
    
  //  ----- Remove Tweets ----
    // MARK: Constants
    
    private struct Constants {
        static let TimeToRemoveOldTweets  = -60*60*24*7
    }
    
    class func removeOldTweets(context: NSManagedObjectContext) {            
                let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
                let weekAgo = Date(timeIntervalSinceNow:
                                   TimeInterval(Constants.TimeToRemoveOldTweets))
                request.predicate = NSPredicate(format: "created < %@", weekAgo as CVarArg)
                
                let results = try? context.fetch(request)
                if let count = results?.count{
                    print ("Убрано \(count) Tweets")
                }
                if let tweets = results  {
                    for tweet in tweets {
                        context.delete(tweet)
                    }
                }
                    try? context.save()
    }

    override public func prepareForDeletion() {
        if let mentionsSet = mentions as? Set<Mention>, mentionsSet.count > 0  {
            for mention in mentionsSet {
            mention.removeFromTweets(self)
            mention.count =  Int32((mention.count) - 1)
                if  (mention.tweets?.filter ({ !($0 as AnyObject).isDeleted }).isEmpty)! {
                    managedObjectContext?.delete(mention)
                }
            }
        }
    }
}

