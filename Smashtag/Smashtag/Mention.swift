//
//  Mension.swift
//  Smashtag
//
//  Created by Tatiana Kornilova on 5/31/17.
//  Copyright © 2017 Stanford University. All rights reserved.
//

import UIKit
import CoreData
import Twitter

class Mention: NSManagedObject {
    static func findOrCreateMention(withKeyword keyword: String,
                                    andType type: String,
                                    andTerm searchTerm: String,
                                    in context: NSManagedObjectContext) throws -> Mention
    {
        let request : NSFetchRequest<Mention> = Mention.fetchRequest()
        //keyword, searchTerm and type is the unique identifier
        request.predicate = NSPredicate(format: "keyword LIKE[cd] %@ AND searchTerm =[cd] %@",
                                                                          keyword, searchTerm)
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert (matches.count == 1, "mension,findorcreatemension -- database inconsistency")
                return matches[0]
            } else {
                let mention = Mention (context: context)
                mention.count = 0
                mention.keyword = keyword.lowercased()
                mention.searchTerm = searchTerm
                mention.type = type
                return mention
            }
        }
        catch {
            throw error
        }
    }
    
    static func checkMention(for tweet: Tweet,
                                    withKeyword keyword: String,
                                    andType type: String,
                                    andTerm searchTerm: String,
                                    in context: NSManagedObjectContext) throws -> Mention
    {
        do {
            let mention = try findOrCreateMention(withKeyword:keyword,
                                               andType: type,
                                               andTerm: searchTerm,
                                               in: context)
            
            if let tweetsSet = mention.tweets as? Set<Tweet>, !tweetsSet.contains(tweet) {
                mention.addToTweets(tweet)
                mention.count =  Int32((mention.count) + 1)
            }
            return mention
            
        } catch {
            throw error
        }
    }
}
