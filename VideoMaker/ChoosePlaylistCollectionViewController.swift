//
//  ChoosePlaylistCollectionViewController.swift
//  VideoMaker
//
//  Created by Tom on 10/8/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit
import Alamofire
class ChoosePlaylistCollectionViewController: UICollectionViewController {
    let kCellReuseIdentifier = "PlaylistCollectionViewCell"
    
    // layout
    var searchBarHeight: CGFloat = 0.0
    
    // for searches
    var searchController: UISearchController!
    var currentSearchString = ""
    
    // for segues
    var segueBackViewController: BaseViewController? // when the song is chosen, the navigation controller will pop back to the original sender
    var seguePlaylistItem: PlaylistItem?

// MARK: - View Controller Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if let searchMusicTrackController = storyboard?.instantiateViewControllerWithIdentifier("SearchMusicTrackTableViewController") as? SearchMusicTrackTableViewController {
            searchMusicTrackController.currentNavigationController = navigationController
            searchController = UISearchController(searchResultsController: searchMusicTrackController)
        }
        searchController.searchBar.sizeToFit()
        
        searchController.dimsBackgroundDuringPresentation = true
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        
        searchBarHeight = 44.0
        searchController.searchBar.frame = CGRectMake(0, 0, UIApplication.sharedApplication().statusBarFrame.size.width, searchBarHeight)
        collectionView?.addSubview(searchController.searchBar)
        searchController.searchBar.placeholder = "search for a song"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Choose Music Track" {
            if let playlistItem = seguePlaylistItem, segueBackViewController = segueBackViewController {
                let chooseMusicViewController = segue.destinationViewController as! ChooseMusicTrackTableViewController
                chooseMusicViewController.playlistItem = playlistItem
                chooseMusicViewController.segueBackViewController = segueBackViewController
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension ChoosePlaylistCollectionViewController {
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return MusicPlaylistAPI.playlists.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(kCellReuseIdentifier, forIndexPath: indexPath) as! ChoosePlaylistCollectionViewCell
        let playlistItem = MusicPlaylistAPI.playlists[indexPath.row]
        cell.request?.cancel()
        cell.playlistNameLabel.text = playlistItem.name
        
        cell.request = Alamofire.request(.GET, playlistItem.thumbnailURL).responseImage() { (_, _, image) in
            switch image {
            case .Success(let image):
                cell.thumbnailImageView.image = image
            case .Failure(_, let error):
                print(error)
            }
        }
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        seguePlaylistItem = MusicPlaylistAPI.playlists[indexPath.row]
        performSegueWithIdentifier("Choose Music Track", sender: nil)
    }
}

extension ChoosePlaylistCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: searchBarHeight + 20.0, left: 0.0, bottom: 0.0, right: 0.0)
    }
}

extension ChoosePlaylistCollectionViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let searchString = searchController.searchBar.text {
            if searchString != "" {
                let searchVC = searchController.searchResultsController as! SearchMusicTrackTableViewController
                searchVC.segueBackViewController = segueBackViewController
                searchVC.searchForMusicWithSearchString(searchString)
            }
        }
    }
}

class ChoosePlaylistCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var playlistNameLabel: UILabel!
    
    var request: Alamofire.Request?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
