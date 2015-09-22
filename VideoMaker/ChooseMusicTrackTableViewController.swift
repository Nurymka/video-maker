//
//  ChooseMusicTrackTableViewController.swift
//  VideoMaker
//
//  Created by Tom on 9/18/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class ChooseMusicTrackTableViewController: UITableViewController {
    
    var tracks: [TrackInfo] = []
    
    // constants
    let kCellIdentifier = "TrackItemCellIdentifier"

    override func viewDidLoad() {
        loadMusic()
    }
    
    func loadMusic() {
        Alamofire.request(MusicAPI.Router.Search("Eminem", 0)).responseJSON { (_, _, resultJSON) in
            switch resultJSON {
            case .Success(let data):
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                    let trackInfos = ((data as! NSDictionary).valueForKey("results") as! [NSDictionary]).map {
                        TrackInfo(id: $0["trackId"] as! Int, trackPreviewURL: $0["previewUri"] as! String, albumCoverURL: $0["thumbnailUri"] as! String, trackName: $0["trackName"] as! String, artistName: $0["artistName"] as! String)
                        }
                    let lastItem = self.tracks.count
                    self.tracks.appendContentsOf(trackInfos)
                    let indexPaths = (lastItem..<self.tracks.count).map { NSIndexPath(forRow: $0, inSection: 0) }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
                    }
                }
            case .Failure(_, let error):
                print(error)
            }
        }
    }
}

extension ChooseMusicTrackTableViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier, forIndexPath: indexPath) as! ChooseMusicTrackViewCell
        
        cell.trackNameLabel.text = tracks[indexPath.row].trackName
        cell.artistNameLabel.text = tracks[indexPath.row].artistName
        
        cell.albumCoverButton.setBackgroundImage(nil, forState: .Normal)
        cell.request?.cancel()
        
        cell.request = Alamofire.request(.GET, tracks[indexPath.row].albumCoverURL).responseImage {
            (request, _, image) in
            switch image {
            case .Success(let image):
                cell.albumCoverButton.setBackgroundImage(image, forState: .Normal)
            case .Failure(_, let error):
                print(error)
            }
        }
        
        return cell
    }
}

extension ChooseMusicTrackTableViewController {
    
}

class ChooseMusicTrackViewCell: UITableViewCell {
    let kTrackItemAlbumCoverImageViewTag = 10
    let kTrackItemTrackLabelTag = 11
    let kTrackItemArtistLabel = 12
    
    @IBOutlet weak var albumCoverButton: UIButton!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    
    var request: Alamofire.Request?
    /*
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

    }
    */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
