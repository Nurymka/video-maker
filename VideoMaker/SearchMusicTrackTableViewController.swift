//
//  SearchMusicTrackTableViewController.swift
//  VideoMaker
//
//  Created by Tom on 9/18/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import AVFoundation

class SearchMusicTrackTableViewController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate {
    
    var tracks: [TrackInfo] = []
    let musicCache = NSCache()
    var audioPlayer: AVAudioPlayer?
    var spinner: UIActivityIndicatorView?
    var currentPlayingSongID: Int = -1
    var currentPlayingCell: SearchMusicTrackViewCell?

    // for music api requests
    var currentResultPage = 0
    var loadingMusic = false
    var currentSearchString = ""
    
    // constants
    let kCellIdentifier = "TrackItemCellIdentifier"
    
    var currentNavigationController: UINavigationController? // used for seguing back to the video playback controller when the song is chosen. because SearchMusicTrackTableViewController is not part of the navigationcontroller stack, it has to be stored
    var segueBackViewController: BaseViewController?
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y + view.frame.size.height > scrollView.contentSize.height * 0.8 {
            if !tracks.isEmpty {
                loadMoreMusicAfterScrolling()
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension SearchMusicTrackTableViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier, forIndexPath: indexPath) as! SearchMusicTrackViewCell
        
        cell.request?.cancel()
        cell.trackNameLabel.text = tracks[indexPath.row].trackName
        cell.artistNameLabel.text = tracks[indexPath.row].artistName
        cell.albumCoverButton.setBackgroundImage(nil, forState: .Normal)
        cell.albumCoverButton.addTarget(self, action: "playPreviewPressed:", forControlEvents: .TouchUpInside)
        
        // because uitableviewcells are reused, button states have to be checked and changed accordingly
        if cell.buttonState == .PauseButton && tracks[indexPath.row].id != currentPlayingSongID {
            cell.changeButtonStateTo(.PlayButton)
        } else if cell.buttonState == .PlayButton && tracks[indexPath.row].id == currentPlayingSongID {
            cell.changeButtonStateTo(.PauseButton)
        }
        
        cell.request = Alamofire.request(.GET, tracks[indexPath.row].albumCoverURL).responseImage { (request, _, image) in
            switch image {
            case .Success(let image):
                cell.albumCoverButton.setBackgroundImage(image, forState: .Normal)
            case .Failure(_, let error):
                print(error)
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let audioPlayer = audioPlayer {
            audioPlayer.stop()
        }
        
        let trackId = tracks[indexPath.row].id
        let trackURL = tracks[indexPath.row].trackPreviewURL
        let artistName = tracks[indexPath.row].artistName
        let trackName = tracks[indexPath.row].trackName
        
        if let currentNavigationController = currentNavigationController {
            if LocalMusicManager.trackExistsOnDisk(trackId: trackId) {
                if let trackInfo = LocalMusicManager.returnTrackInfoFromDisk(trackId: trackId), segueBackViewController = segueBackViewController {
                    segueBackViewController.musicTrackInfo = trackInfo
                    currentNavigationController.popToViewController(segueBackViewController, animated: true)
                }
            } else {
                if let musicData = musicCache.objectForKey(trackURL) as? NSData, segueBackViewController = segueBackViewController {
                    if LocalMusicManager.writeMusicDataToDisk(musicData, trackId: trackId, trackName: trackName, artistName: artistName), let trackInfo = LocalMusicManager.returnTrackInfoFromDisk(trackId: trackId) {
                        segueBackViewController.musicTrackInfo = trackInfo
                        currentNavigationController.popToViewController(segueBackViewController, animated: true)
                    }
                } else {
                    Alamofire.request(.GET, trackURL).responseData() { (_, _, data: Result<NSData>) in
                        switch data {
                        case .Success(let data):
                            if LocalMusicManager.writeMusicDataToDisk(data, trackId: trackId, trackName: trackName, artistName: artistName), let trackInfo = LocalMusicManager.returnTrackInfoFromDisk(trackId: trackId), segueBackViewController = self.segueBackViewController {
                                segueBackViewController.musicTrackInfo = trackInfo
                                currentNavigationController.popToViewController(segueBackViewController, animated: true)
                            }
                        case .Failure(_, let error):
                            print(error)
                        }
                    }
                }
            }
        }
    }
}

// MARK: Button Touch Handling
extension SearchMusicTrackTableViewController {
    func playPreviewPressed(sender: AnyObject) {
        func playTrackFromData(data: NSData, andConfigureButtonStateForCell cell: SearchMusicTrackViewCell, inIndexPath indexPath: NSIndexPath) {
            self.playTrackFromData(data)
            cell.changeButtonStateTo(.PauseButton)
            if let lastPlayedCell = currentPlayingCell {
                if lastPlayedCell !== cell { // conditional is needed because of reused cells in table view (prevents the bug where a track is played from one cell, and then another track is played from another cell, but cells point to the same exact object)
                    lastPlayedCell.changeButtonStateTo(.PlayButton)
                }
            }
            currentPlayingCell = cell
            currentPlayingSongID = tracks[indexPath.row].id
        }
        
        let buttonPosition = (sender as! UIButton).convertPoint(CGPointZero, toView: tableView)
        if let indexPath = tableView.indexPathForRowAtPoint(buttonPosition), cell = tableView.cellForRowAtIndexPath(indexPath) as? SearchMusicTrackViewCell {
            if cell.buttonState == .PlayButton {
                cell.changeButtonStateTo(.LoadingPreview)
                let trackURL = tracks[indexPath.row].trackPreviewURL
                cell.request?.cancel()
                print(trackURL)
                print(tracks[indexPath.row].id)
                if let trackData = musicCache.objectForKey(trackURL) as? NSData {
                    playTrackFromData(trackData, andConfigureButtonStateForCell: cell, inIndexPath: indexPath)
                } else {
                    Alamofire.request(.GET, trackURL).responseData() { (_, _, data: Result<NSData>) in
                        switch data {
                        case .Success(let track):
                            self.musicCache.setObject(track, forKey: trackURL)
                            playTrackFromData(track, andConfigureButtonStateForCell: cell, inIndexPath: indexPath)
                        case .Failure(_, let error):
                            print(error)
                        }
                    }
                }
            } else if cell.buttonState == .PauseButton {
                if audioPlayer!.playing {
                    audioPlayer!.stop()
                    cell.changeButtonStateTo(.PlayButton)
                    currentPlayingCell = nil
                    currentPlayingSongID = -1
                }
            }
        }
    }
    
    func playTrackFromData(data: NSData) {
        if let audioPlayer = audioPlayer {
            audioPlayer.stop()
        }
        if let audioPlayer = try? AVAudioPlayer(data: data, fileTypeHint: AVFileTypeAppleM4A) {
            self.audioPlayer = audioPlayer
            audioPlayer.numberOfLoops = -1
            audioPlayer.play()
        }
    }
}

// MARK: Music API Requests
extension SearchMusicTrackTableViewController {
    func searchForMusicWithSearchString(searchString: String) {
        if loadingMusic {
            return
        }
        
        loadingMusic = true
        
        currentResultPage = 0
        tracks = []
        self.tableView.reloadData()
        Alamofire.request(MusicSearchAPI.Router.Search(searchString, currentResultPage)).responseJSON { (_, _, resultJSON) in
            switch resultJSON {
            case .Success(let data):
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                    let trackInfos = ((data as! NSDictionary).valueForKey("results") as! [NSDictionary]).map {
                        TrackInfo(id: $0["trackId"] as! Int, trackPreviewURL: $0["previewUri"] as! String, albumCoverURL: MusicSearchAPI.returnThumbnailUrlStringForDictObject($0["thumbnailUri"]!), trackName: $0["trackName"] as! String, artistName: $0["artistName"] as! String)
                    }
                    let lastItem = self.tracks.count
                    self.tracks.appendContentsOf(trackInfos)
                    let indexPaths = (lastItem..<self.tracks.count).map { NSIndexPath(forRow: $0, inSection: 0) }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
                    }
                    
                    self.currentSearchString = searchString
                    self.currentResultPage++
                }
            case .Failure(_, let error):
                print(error)
            }
            self.loadingMusic = false
        }
    }
    
    func loadMoreMusicAfterScrolling() {
        if loadingMusic {
            return
        }
        
        loadingMusic = true
        NSLog("currentResultPage: \(currentResultPage)")
        Alamofire.request(MusicSearchAPI.Router.Search(currentSearchString, currentResultPage)).responseJSON { (_, _, resultJSON) in
            switch resultJSON {
            case .Success(let data):
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                    let trackInfos = ((data as! NSDictionary).valueForKey("results") as! [NSDictionary]).map {
                        TrackInfo(id: $0["trackId"] as! Int, trackPreviewURL: $0["previewUri"] as! String, albumCoverURL: MusicSearchAPI.returnThumbnailUrlStringForDictObject($0["thumbnailUri"]!), trackName: $0["trackName"] as! String, artistName: $0["artistName"] as! String)
                    }
                    let lastItem = self.tracks.count
                    self.tracks.appendContentsOf(trackInfos)
                    let indexPaths = (lastItem..<self.tracks.count).map { NSIndexPath(forRow: $0, inSection: 0) }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
                    }
                    
                    self.currentResultPage++
                }
            case .Failure(_, let error):
                print(error)
            }
            self.loadingMusic = false
        }
    }
}

class SearchMusicTrackViewCell: UITableViewCell {
    @IBOutlet weak var albumCoverButton: UIButton!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    
    var request: Alamofire.Request?
    var buttonState: ButtonState = .PlayButton

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // to Tony: pretty sure that there is a more elegant solution for changing button states
    enum ButtonState {
        case PlayButton
        case LoadingPreview
        case PauseButton
    }
    
    func changeButtonStateTo(state: ButtonState) {
        switch state {
        case .PlayButton:
            buttonState = .PlayButton
            spinnerView.stopAnimating()
            albumCoverButton.setImage(UIImage(named: "playIcon"), forState: UIControlState.Normal)
            albumCoverButton.userInteractionEnabled = true
        case .LoadingPreview:
            buttonState = .LoadingPreview
            albumCoverButton.setImage(UIImage(), forState: .Normal)
            albumCoverButton.userInteractionEnabled = false
            spinnerView.startAnimating()
        case .PauseButton:
            buttonState = .PauseButton
            spinnerView.stopAnimating()
            albumCoverButton.setImage(UIImage(named: "pauseIcon"), forState: .Normal)
            albumCoverButton.userInteractionEnabled = true
        }
    }
}
