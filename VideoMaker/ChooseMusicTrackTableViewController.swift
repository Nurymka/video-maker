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
import AVFoundation

class ChooseMusicTrackTableViewController: UITableViewController {
    
    var tracks: [TrackInfo] = []
    let musicCache = NSCache()
    var audioPlayer: AVAudioPlayer?
    var spinner: UIActivityIndicatorView?
    var currentPlayingSongID: Int = -1
    var currentPlayingCell: ChooseMusicTrackViewCell?
    // constants
    let kCellIdentifier = "TrackItemCellIdentifier"

    override func viewDidLoad() {
        loadMusic()
    }
    
    func loadMusic() {
        Alamofire.request(MusicAPI.Router.Search("Twenty One Pilots", 0)).responseJSON { (_, _, resultJSON) in
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
        let trackURL = tracks[indexPath.row].trackPreviewURL
        let playbackViewController = self.navigationController?.viewControllers.filter({$0 is VideoPlaybackViewController}).first as? VideoPlaybackViewController
        
        if FileManager.trackExistsOnDisk(trackURL: trackURL) {
            if let diskTrackURL = FileManager.returnTrackURLFromDisk(trackURL: trackURL), playbackViewController = playbackViewController {
                playbackViewController.musicTrackURL = diskTrackURL
                self.navigationController?.popToViewController(playbackViewController, animated: true)
            }
        } else {
            if let trackData = musicCache.objectForKey(trackURL) as? NSData, playbackViewController = playbackViewController {
                if FileManager.writeTrackDataToDisk(trackData, withFileName: trackURL), let diskTrackURL = FileManager.returnTrackURLFromDisk(trackURL: trackURL) {
                    playbackViewController.musicTrackURL = diskTrackURL
                    self.navigationController?.popToViewController(playbackViewController, animated: true)
                }
            } else {
                Alamofire.request(.GET, trackURL).responseData() { (_, _, data: Result<NSData>) in
                    switch data {
                    case .Success(let track):
                        if FileManager.writeTrackDataToDisk(track, withFileName: trackURL), let diskTrackURL = FileManager.returnTrackURLFromDisk(trackURL: trackURL), playbackViewController = playbackViewController {
                            playbackViewController.musicTrackURL = diskTrackURL
                            self.navigationController?.popToViewController(playbackViewController, animated: true)
                        }
                    case .Failure(_, let error):
                        print(error)
                    }
                }
            }
        }
    }
}

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
class ChooseMusicTrackViewCell: UITableViewCell {
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
