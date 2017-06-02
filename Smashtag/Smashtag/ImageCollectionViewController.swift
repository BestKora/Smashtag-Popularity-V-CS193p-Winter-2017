//
//  ImageCollectionViewController.swift
//  Smashtag
//
//  Created by Tatiana Kornilova on 7/12/15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit
import Twitter

public struct TweetMedia: CustomStringConvertible
{
    var tweet: Twitter.Tweet
    var media: MediaItem
    
    public var description: String { return "\(tweet): \(media)" }
}

// Subscripting делает работу с NSCache более удобной
// Реализовано Michel Deiman

class Cache: NSCache<NSURL, NSData> {
    subscript(key: URL) -> Data? {
        get {
            return object(forKey: key as NSURL) as Data?
        }
        set {
            if let data = newValue {
                setObject(data as NSData, forKey: key as NSURL,
                                            cost: data.count / 1024)
            } else {
                removeObject(forKey: key as NSURL)
            }
        }
    }
}

class ImageCollectionViewController: UICollectionViewController,
                                     UICollectionViewDelegateFlowLayout {

    var tweets: [Array<Twitter.Tweet>] = [] {
        didSet {
            images = tweets.flatMap({$0})
                .map { tweet in
                    tweet.media.map { TweetMedia(tweet: tweet, media: $0) }}
                .flatMap({$0})
        }
    }
    
    fileprivate var images = [TweetMedia]()
    private var cache = Cache()
    
    private var layoutFlow = UICollectionViewFlowLayout()
    private var layoutWaterfall = CHTCollectionViewWaterfallLayout()
    
    
    var predefinedSize: CGSize {
        return CGSize(width: predefinedWidth, height: predefinedWidth)
    }
    
    var predefinedWidth: CGFloat {
        return floor(((collectionView?.bounds.width)! -
            Constants.minimumColumnSpacing * (Constants.columnCountFlowLayout - 1.0 ) -
            Constants.sectionInset.right * 2.0) / Constants.columnCountFlowLayout)
    }
    
    fileprivate struct Constants {
        
        static let minImageCellWidth: CGFloat = 60
        static let sizeSetting = CGSize(width: 120.0, height: 120.0)
        
        static let columnCountWaterfall = 3
        static let columnCountWaterfallMax = 8
        static let columnCountWaterfallMin = 1
        
        static let columnCountFlowLayout: CGFloat = 3
        
        static let minimumColumnSpacing:CGFloat = 2
        static let minimumInteritemSpacing:CGFloat = 2
        static let sectionInset = UIEdgeInsets (top: 2, left: 2, bottom: 2, right: 2)
    }
    
    private struct Storyboard {
        static let CellReuseIdentifier = "Image Cell"
        static let SegueIdentifier = "Show Tweet"
     }

    var scale: CGFloat = 1 {
        didSet {
            collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        collectionView?.addGestureRecognizer(UIPinchGestureRecognizer(target: self,
                          action: #selector(ImageCollectionViewController.zoom(_:))))
       installsStandardGestureForInteractiveMovement = true
    }
    
    //MARK: - Настройка Layout CollectionView
    private func setupLayout(){
        
        // WaterfallLayout
        layoutWaterfall.columnCount = Constants.columnCountWaterfall
        layoutWaterfall.minimumColumnSpacing = Constants.minimumColumnSpacing
        layoutWaterfall.minimumInteritemSpacing = Constants.minimumInteritemSpacing
        
        // FlowLayout
        layoutFlow.minimumInteritemSpacing = Constants.minimumInteritemSpacing
        layoutFlow.minimumLineSpacing = Constants.minimumColumnSpacing
        layoutFlow.sectionInset = Constants.sectionInset
        layoutFlow.itemSize = predefinedSize
        
        collectionView?.collectionViewLayout = layoutWaterfall
    }

    @IBAction func changeLayout(_ sender: UIBarButtonItem) {
        if let layout = collectionView?.collectionViewLayout {
            if layout is CHTCollectionViewWaterfallLayout {
                collectionView?.setCollectionViewLayout(layoutFlow, animated: true)
            } else {
                collectionView?.setCollectionViewLayout(layoutWaterfall, animated: true)
            }
        }
    }
   
    func zoom(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            scale *= gesture.scale
            gesture.scale = 1.0
        }
    }
    
    deinit {
        cache.removeAllObjects()
    }

    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView:
                                                   UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
            return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
                          withReuseIdentifier: Storyboard.CellReuseIdentifier,
                                          for: indexPath)
        if let imageCell = cell as? ImageCollectionViewCell {

            imageCell.cache = cache
            imageCell.tweetMedia = images[indexPath.row]
        }
            return cell
    }
    
// MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView,
             layout collectionViewLayout: UICollectionViewLayout,
                 sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let ratio = CGFloat(images[indexPath.row].media.aspectRatio)
        var sizeSetting =  predefinedSize
        var maxCellWidth = collectionView.bounds.size.width

        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            maxCellWidth = collectionView.bounds.size.width  -
                        layout.minimumInteritemSpacing * 2.0 -
                        layout.sectionInset.right * 2.0
            sizeSetting = layout.itemSize
        }
        
        let size = CGSize(width: sizeSetting.width * scale,
                          height: sizeSetting.height * scale)
        let cellWidth = min (max (size.width , Constants.minImageCellWidth),maxCellWidth)
        return (CGSize(width: cellWidth, height: cellWidth / ratio))
    }
    
    
    override func collectionView(_ collectionView: UICollectionView,
                          canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                       moveItemAt sourceIndexPath: IndexPath,
                          to destinationIndexPath: IndexPath) {
        
        let temp = images[destinationIndexPath.row]
        images[destinationIndexPath.row] = images[sourceIndexPath.row]
        images[sourceIndexPath.row] = temp
        collectionView.collectionViewLayout.invalidateLayout()
    }
   
    // MARK: - Navigation
    
    @IBAction private func toRootViewController(_ sender: UIBarButtonItem) {
       _ = navigationController?.popToRootViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.SegueIdentifier {
            if let ttvc = segue.destination as? TweetTableViewController {
                if let cell = sender as? ImageCollectionViewCell,
                    let tweetMedia = cell.tweetMedia {
                    
                     ttvc.newTweets = [tweetMedia.tweet]
                }
            }
        }
    }
 }

extension ImageCollectionViewController:
                                CHTCollectionViewDelegateWaterfallLayout{
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtCHT indexPath: IndexPath) -> CGSize {
        
        adjustWaterfallColumnCount(collectionView)
        let ratio = CGFloat(images[indexPath.row].media.aspectRatio)
        let sizeSetting =  predefinedSize
        var maxCellWidth = collectionView.bounds.size.width
        
        if let layout = collectionViewLayout as? CHTCollectionViewWaterfallLayout {
            maxCellWidth = collectionView.bounds.size.width  -
                layout.minimumInteritemSpacing * 2.0 -
                layout.sectionInset.right * 2.0
        }
        let size = CGSize(width: sizeSetting.width * scale,
                          height: sizeSetting.height * scale)
        let cellWidth = min (max (size.width , Constants.minImageCellWidth),maxCellWidth)
        return (CGSize(width: cellWidth, height: cellWidth / ratio))
    }
    
    private func adjustWaterfallColumnCount(_ collectionView: UICollectionView) {
        if let waterfallLayout =
            collectionView.collectionViewLayout as? CHTCollectionViewWaterfallLayout {
            let newColumnNumber = Int(CGFloat(Constants.columnCountWaterfall) / scale)
            waterfallLayout.columnCount =
                min (max (newColumnNumber,Constants.columnCountWaterfallMin),
                     Constants.columnCountWaterfallMax)
        }
    }
}

