//
//  ChoosePlaylistCollectionViewController.swift
//  VideoMaker
//
//  Created by Tom on 10/8/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class ChoosePlaylistCollectionViewController: UICollectionViewController {
    let kCellReuseIdentifier = "PlaylistCollectionViewCell"
    
    // layout
    var searchBarHeight: CGFloat = 0.0
    
    // for searches
    var searchController: SongSearchController!
    var currentSearchString = ""
    
    // for segues
    var segueBackViewController: BaseViewController? // when the song is chosen, the navigation controller will pop back to the original sender
    var seguePlaylistItem: PlaylistItem?

// MARK: - View Controller Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBarAppearance()
        if let searchMusicTrackController = storyboard?.instantiateViewControllerWithIdentifier("SearchMusicTrackTableViewController") as? SearchMusicTrackTableViewController {
            searchMusicTrackController.currentNavigationController = navigationController
            searchController = SongSearchController(searchResultsController: searchMusicTrackController)
        }
        searchController.searchBar.sizeToFit()
        
        searchController.dimsBackgroundDuringPresentation = true
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.delegate = self
        definesPresentationContext = true
        
        searchController.searchBar.scopeButtonTitles = [] // sets up the frame in the background
        searchBarHeight = searchController.searchBar.frame.size.height
        collectionView?.addSubview(searchController.searchBar)
        searchController.searchBar.placeholder = "search for a song"
        
        UITextField.my_appearanceWhenContainedIn(UISearchBar).defaultTextAttributes = [NSFontAttributeName: FontKit.searchBarText]
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Choose Music Track" {
            if let playlistItem = seguePlaylistItem, segueBackViewController = segueBackViewController {
                let chooseMusicViewController = segue.destinationViewController as! ChooseMusicTrackTableViewController
                navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
                chooseMusicViewController.title = playlistItem.name
                chooseMusicViewController.playlistItem = playlistItem
                chooseMusicViewController.segueBackViewController = segueBackViewController
            }
        }
    }
    
// MARK: - UI Related
    func configureNavigationBarAppearance() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(key: .btnBareCross), style: .Plain, target: self, action: "backButtonPressed")
        navigationItem.title = "pick a song"
        navigationController?.navigationBar.translucent = false
        navigationController?.navigationBar.barTintColor = StyleKit.lightPurple
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: FontKit.navBarTitle, NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
    }
    
// MARK: - Button Touch Handlers
    func backButtonPressed() {
        dismissViewControllerAnimated(true, completion: nil)
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
        
        cell.request = Alamofire.request(.GET, playlistItem.thumbnailURL).responseImage() { response in
            switch response.result {
            case .Success(let image):
                cell.thumbnailImageView.image = image
            case .Failure(let error):
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

extension ChoosePlaylistCollectionViewController: UISearchControllerDelegate {
    func willPresentSearchController(searchController: UISearchController) {
        
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
