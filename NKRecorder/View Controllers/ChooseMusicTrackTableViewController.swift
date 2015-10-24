//
//  ChooseMusicTrackTableViewController.swift
//  VideoMaker
//
//  Created by Tom on 10/9/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit
import Alamofire
import AVFoundation

class ChooseMusicTrackTableViewController: UITableViewController {
    var tracks: [TrackInfo] = []
    let musicCache = NSCache()
    var audioPlayer: AVAudioPlayer?
    var spinner: UIActivityIndicatorView?
    var currentPlayingSongID: Int = -1
    var currentPlayingCell: ChooseMusicTrackViewCell?
    
    var playlistItem: PlaylistItem? // if it exists, tracks are loaded from this playlist
    var segueBackViewController: BaseViewController?
    // for music api requests
    var currentResultPage = 1
    var totalResultPages = -1
    var loadingMusic = false
    
    // constants
    let kCellIdentifier = "TrackItemCellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if totalResultPages == -1 {
            loadMusic()
        }
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.separatorColor = StyleKit.lightPurple
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y + view.frame.size.height > scrollView.contentSize.height * 0.8 {
            if !tracks.isEmpty && currentResultPage <= totalResultPages {
                loadMusic()
            }
        }
    }
}

// MARK: UITableViewDelegate
extension ChooseMusicTrackTableViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier, forIndexPath: indexPath) as! ChooseMusicTrackViewCell
        
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
        
        let trackURL = tracks[indexPath.row].trackPreviewURL
        let trackId = tracks[indexPath.row].id
        let artistName = tracks[indexPath.row].artistName
        let trackName = tracks[indexPath.row].trackName
        
        // if (music is on disk) else if (music is cached but not on disk) else if (music is not cached nor it's on disk)
        if LocalMusicManager.trackExistsOnDisk(trackId: trackId) {
            if let trackInfo = LocalMusicManager.returnTrackInfoFromDisk(trackId: trackId), segueBackViewController = segueBackViewController {
                segueBackViewController.musicTrackInfo = trackInfo
                dismissViewControllerAnimated(true, completion: nil)
            }
        } else {
            if let musicData = musicCache.objectForKey(trackId) as? NSData, segueBackViewController = segueBackViewController {
                if LocalMusicManager.writeMusicDataToDisk(musicData, trackId: trackId, trackName: trackName, artistName: artistName), let trackInfo = LocalMusicManager.returnTrackInfoFromDisk(trackId: trackId) {
                    segueBackViewController.musicTrackInfo = trackInfo
                    dismissViewControllerAnimated(true, completion: nil)
                }
            } else {
                Alamofire.request(.GET, trackURL).responseData() { (_, _, data: Result<NSData>) in
                    switch data {
                    case .Success(let data):
                        if LocalMusicManager.writeMusicDataToDisk(data, trackId: trackId, trackName: trackName, artistName: artistName), let trackInfo = LocalMusicManager.returnTrackInfoFromDisk(trackId: trackId), segueBackViewController = self.segueBackViewController {
                            segueBackViewController.musicTrackInfo = trackInfo
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                    case .Failure(_, let error):
                        print(error)
                    }
                }
            }
        }
    }
}

// MARK: Button Touch Handling
extension ChooseMusicTrackTableViewController {
    func playPreviewPressed(sender: AnyObject) {
        func playTrackFromData(data: NSData, andConfigureButtonStateForCell cell: ChooseMusicTrackViewCell, inIndexPath indexPath: NSIndexPath) {
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
        if let indexPath = tableView.indexPathForRowAtPoint(buttonPosition), cell = tableView.cellForRowAtIndexPath(indexPath) as? ChooseMusicTrackViewCell {
            if cell.buttonState == .PlayButton {
                cell.changeButtonStateTo(.LoadingPreview)
                let trackURL = tracks[indexPath.row].trackPreviewURL
                let trackId = tracks[indexPath.row].id
                cell.request?.cancel()
                print(trackURL)
                print(trackId)
                if let trackData = musicCache.objectForKey(trackId) as? NSData {
                    playTrackFromData(trackData, andConfigureButtonStateForCell: cell, inIndexPath: indexPath)
                } else {
                    Alamofire.request(.GET, trackURL).responseData() { (_, _, data: Result<NSData>) in
                        switch data {
                        case .Success(let track):
                            self.musicCache.setObject(track, forKey: trackId)
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
extension ChooseMusicTrackTableViewController {
    func loadMusic() {
        if loadingMusic {
            return
        }
        
        loadingMusic = true
        NSLog("currentResultPage: \(currentResultPage) in totalResultPages: \(totalResultPages)")
        if let playlistItem = playlistItem {
            Alamofire.request(MusicPlaylistAPI.Router.Tracklist(playlistItem.tagId, currentResultPage)).responseJSON { (request, _, resultJSON) in
                switch resultJSON {
                case .Success(let data):
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                        let dataResult = (data as! NSDictionary).valueForKey("result") as! NSDictionary
                        let trackInfos = (dataResult.valueForKey("content") as! [NSDictionary]).map({ (dic: NSDictionary) -> TrackInfo in
                            let id = dic["trackId"] as? Int
                            let trackPreviewURL = dic["previewUri"] as? String
                            let trackName = (dic["song"] as! NSDictionary).valueForKey("title") as? String
                            let artistName = (dic["author"] as! NSDictionary).valueForKey("name") as? String
                            
                            if let id = id, trackPreviewURL = trackPreviewURL, trackName = trackName, artistName = artistName {
                                return TrackInfo(
                                    id: id,
                                    trackPreviewURL: trackPreviewURL,
                                    albumCoverURL: MusicSearchAPI.returnThumbnailUrlStringForDictObject((dic["album"] as! NSDictionary).valueForKey("thumbnailUri")),
                                    trackName: trackName,
                                    artistName: artistName
                                    )
                            } else {
                                return TrackInfo(id: -1, trackPreviewURL: "", albumCoverURL: "", trackName: "", artistName: "")
                            }
                        }).filter({ $0.id != -1 })

                        let lastItem = self.tracks.count
                        self.tracks.appendContentsOf(trackInfos)
                        let indexPaths = (lastItem..<self.tracks.count).map { NSIndexPath(forRow: $0, inSection: 0) }
                        
                        if self.totalResultPages == -1 {
                            self.totalResultPages = dataResult.valueForKey("totalPages") as! Int
                        }
                            
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
}

class ChooseMusicTrackViewCell: UITableViewCell {
    @IBOutlet weak var albumCoverButton: UIButton!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    
    override var separatorInset: UIEdgeInsets {
        get { return UIEdgeInsetsZero } set {}
    }
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
