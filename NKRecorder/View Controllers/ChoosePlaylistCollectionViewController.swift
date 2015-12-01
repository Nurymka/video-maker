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
    var playlists: [PlaylistItem] = []
    var loadingPlaylists = false
    // layout
    //var searchBarHeight: CGFloat = 0.0
    
    // for searches
    //var searchController: SongSearchController!
    //var currentSearchString = ""
    
    // for segues
    var segueBackViewController: BaseViewController? // when the song is chosen, the navigation controller will pop back to the original sender
    var seguePlaylistItem: PlaylistItem?
    
    // navigation bar related
    var initialBarTintColor: UIColor?
    var initialTintColor: UIColor?
    
// MARK: - View Controller Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBarAppearance()
//        if let searchMusicTrackController = storyboard?.instantiateViewControllerWithIdentifier("SearchMusicTrackTableViewController") as? SearchMusicTrackTableViewController {
//            searchMusicTrackController.currentNavigationController = navigationController
//            searchMusicTrackController.musicDelegate = self
//            searchController = SongSearchController(searchResultsController: searchMusicTrackController)
//        }
//        searchController.searchBar.sizeToFit()
//        
//        searchController.dimsBackgroundDuringPresentation = true
//        searchController.hidesNavigationBarDuringPresentation = false
//        searchController.searchBar.delegate = self
//        searchController.delegate = self
//        definesPresentationContext = true
//        
//        searchController.searchBar.scopeButtonTitles = [] // sets up the frame in the background
//        searchBarHeight = searchController.searchBar.frame.size.height
//        collectionView?.addSubview(searchController.searchBar)
//        searchController.searchBar.placeholder = "search for a song"
//        
//        UITextField.my_appearanceWhenContainedIn(UISearchBar).defaultTextAttributes = [NSFontAttributeName: FontKit.searchBarText]
        loadPlaylists()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Choose Music Track" {
            if let playlistItem = seguePlaylistItem, segueBackViewController = segueBackViewController {
                let chooseMusicViewController = segue.destinationViewController as! ChooseMusicTrackTableViewController
                navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
                chooseMusicViewController.title = playlistItem.name
                chooseMusicViewController.playlistItem = playlistItem
                chooseMusicViewController.segueBackViewController = segueBackViewController
                chooseMusicViewController.musicDelegate = self
            }
        }
    }
    
// MARK: - Network Requests
    func loadPlaylists() {
        if loadingPlaylists {
            return
        }
        
        loadingPlaylists = true
        Alamofire.request(MusicPlaylistAPI.PlaylistListRouter.PlaylistList()).responseJSON { response in
            switch response.result {
            case .Success(let data):
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                    let dataResult = (data as! NSDictionary).valueForKey("result") as! [NSDictionary]
                    let playlistItems = dataResult.map({ (dic: NSDictionary) -> PlaylistItem in
                        let tagId = dic["tagId"] as? Int
                        let name = dic["displayName"] as? String
                        let thumbnailURL = dic["coverUri"] as? String
                        
                        if let tagId = tagId, name = name, thumbnailURL = thumbnailURL {
                            return PlaylistItem(thumbnailURL: thumbnailURL, name: name, tagId: tagId)
                        } else {
                            return PlaylistItem(thumbnailURL: "", name: "", tagId: -1)
                        }
                    }).filter({ $0.tagId != -1}).filter({ !$0.name.containsString("muser") })
                    
                    let lastItem = self.playlists.count
                    self.playlists.appendContentsOf(playlistItems)
                    let indexPaths = (lastItem..<self.playlists.count).map { NSIndexPath(forRow: $0, inSection: 0) }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.collectionView?.insertItemsAtIndexPaths(indexPaths)
                    }
                }
            case .Failure(let error):
                print(error)
            }
            self.loadingPlaylists = false
        }
    }
    
// MARK: - UI Related
    func configureNavigationBarAppearance() {
        initialBarTintColor = navigationController?.navigationBar.barTintColor
        initialTintColor = navigationController?.navigationBar.tintColor
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(key: .btnBareCross), style: .Plain, target: self, action: "backButtonPressed")
        navigationItem.title = "pick a song"
        navigationController?.navigationBar.translucent = false
        navigationController?.navigationBar.barTintColor = StyleKit.lightPurple
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: FontKit.navBarTitle, NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
    }
    
    func navigationBarAppearanceBackToDefault() {
        navigationController?.navigationBar.translucent = true
        navigationController?.navigationBar.barTintColor = initialBarTintColor
        navigationController?.navigationBar.tintColor = initialTintColor
    }
    
// MARK: - Button Touch Handlers
    func backButtonPressed() {
        navigationBarAppearanceBackToDefault()
        dismissViewControllerAnimated(true, completion: nil)
    }
}
// MARK: - UICollectionViewDataSource
extension ChoosePlaylistCollectionViewController {
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //return MusicPlaylistAPI.playlists.count
        return playlists.count;
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(kCellReuseIdentifier, forIndexPath: indexPath) as! ChoosePlaylistCollectionViewCell
        //let playlistItem = MusicPlaylistAPI.playlists[indexPath.row]
        let playlistItem = playlists[indexPath.row];
        
        cell.playlistNameLabel.text = playlistItem.name
        
        cell.thumbnailImageView.sd_setImageWithURL(NSURL(string: playlistItem.thumbnailURL)!)
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //seguePlaylistItem = MusicPlaylistAPI.playlists[indexPath.row]
        seguePlaylistItem = playlists[indexPath.row]
        performSegueWithIdentifier("Choose Music Track", sender: nil)
    }
}

extension ChoosePlaylistCollectionViewController: UICollectionViewDelegateFlowLayout {
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: searchBarHeight + 20.0, left: 0.0, bottom: 0.0, right: 0.0)
//    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if DeviceType.IS_IPHONE_6P {
            return CGSize(width: 200.0, height: 200.0)
        } else if DeviceType.IS_IPHONE_6 {
            return CGSize(width: 180.0, height: 180.0)
        } else {
            return CGSize(width: 150.0, height: 150.0)
        }
    }
}

// Reseting nav bar appearance
extension ChoosePlaylistCollectionViewController: ChooseMusicTrackTableViewControllerDelegate, SearchMusicTrackTableViewControllerDelegate {
    func musicTrackChosen() {
        navigationBarAppearanceBackToDefault()
    }
    
    func searchMusicTrackChosen() {
        navigationBarAppearanceBackToDefault()
    }
}

//extension ChoosePlaylistCollectionViewController: UISearchBarDelegate {
//    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
//        if let searchString = searchController.searchBar.text {
//            if searchString != "" {
//                let searchVC = searchController.searchResultsController as! SearchMusicTrackTableViewController
//                searchVC.segueBackViewController = segueBackViewController
//                searchVC.searchForMusicWithSearchString(searchString)
//            }
//        }
//    }
//}

//extension ChoosePlaylistCollectionViewController: UISearchControllerDelegate {
//    func willPresentSearchController(searchController: UISearchController) {
//        
//    }
//}

class ChoosePlaylistCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var playlistNameLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}




//FIXME: - Move to ScreenMacros.swift, temporarily here because xcode doesn't see them there 
struct ScreenSize
{
    static let SCREEN_WIDTH = UIScreen.mainScreen().bounds.size.width
    static let SCREEN_HEIGHT = UIScreen.mainScreen().bounds.size.height
    static let SCREEN_MAX_LENGTH = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType
{
    static let IS_IPHONE_4_OR_LESS =  UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
    static let IS_IPHONE_5 = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
    static let IS_IPHONE_6 = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
    static let IS_IPHONE_6P = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
}



