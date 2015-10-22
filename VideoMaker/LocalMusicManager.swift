//
//  Utilities.swift
//  VideoMaker
//
//  Created by Tom on 9/23/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import Foundation

// FileManager is used to save music tracks as NSData objects to /Library/Caches/VideoMakerMusicCache/{trackID}.m4a
// To get access to the music data URL, use returnTrackInfoFromDisk(_:) to get the corresponding music id, and then use the returnMusicDataFromTrackId(_:)
class LocalMusicManager {
    static let kVideoMakerMusicCacheDirectory = "VideoMakerMusicCache"
    
    static func writeMusicDataToDisk(data: NSData, trackId: Int, trackName: String, artistName: String) -> Bool {
        let fm = NSFileManager()
        let cachesURL = fm.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
        let trackDirectoryURL = cachesURL.URLByAppendingPathComponent(kVideoMakerMusicCacheDirectory) // creates a directory at path /Library/Caches/VideoMakerMusicCache/ if it doesn't exist
        var isDirectory = ObjCBool(true)
        if !NSFileManager.defaultManager().fileExistsAtPath(trackDirectoryURL.path!, isDirectory: &isDirectory) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(trackDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Directory couldn't be added at \(trackDirectoryURL): \(error)")
            }
        }
        
        let fileName = "\(trackId)" + ".m4a"
        let trackPathURL = trackDirectoryURL.URLByAppendingPathComponent(fileName)
        if !NSFileManager.defaultManager().fileExistsAtPath(trackPathURL.path!) {
            if NSFileManager.defaultManager().createFileAtPath(trackPathURL.path!, contents: data, attributes: nil) {
                return writeTrackInfoDataToDisk(trackId: trackId, trackName: trackName, artistName: artistName)
            }
        }
        return false
    }
    
    static func returnTrackInfoFromDisk(trackId trackId: Int) -> TrackInfoLocal? {
        if let musicDataURL = returnMusicDataFromTrackId(trackId: trackId) {
            let trackInfoURL = trackInfoURLfromMusicDataURL(musicDataURL)
            
            if NSFileManager.defaultManager().fileExistsAtPath(trackInfoURL.path!) {
                let data = NSFileManager.defaultManager().contentsAtPath(trackInfoURL.path!)
                return TrackInfoLocal.unarchive(data)
            } else {
                print("trackInfo doesn't exist at path: \(trackInfoURL.path!)")
                return nil
            }
        } else {
            print("at function \(__FUNCTION__) musicDataURL not found")
        }
    }
    
    static func returnMusicDataFromTrackId(trackId trackId: Int) -> NSURL? {
        if trackExistsOnDisk(trackId: trackId) {
            return musicDataURLFromTrackId(trackId)
        } else {
            print("no music data exists corresponding to the track id \(trackId) at path \(musicDataURLFromTrackId(trackId).path!)")
            return nil
        }
    }
    
    static func trackExistsOnDisk(trackId trackId: Int) -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(musicDataURLFromTrackId(trackId).path!)
    }
    
// MARK: - Private
    private static func writeTrackInfoDataToDisk(trackId trackId: Int, trackName: String, artistName: String) -> Bool {
        let musicDataURL = musicDataURLFromTrackId(trackId)
        let trackInfoURL = trackInfoURLfromMusicDataURL(musicDataURL)
        
        let archivedLocalTrackInfo = TrackInfoLocal(id: trackId, trackName: trackName, artistName: artistName).archive()
        if !NSFileManager.defaultManager().fileExistsAtPath(trackInfoURL.path!) {
            return NSFileManager.defaultManager().createFileAtPath(trackInfoURL.path!, contents: archivedLocalTrackInfo, attributes: nil)
        }
        return false
    }
    
    private static func musicDataURLFromTrackId(trackId: Int) -> NSURL {
        let fm = NSFileManager()
        let cachesURL = fm.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
        let musicDataURL = cachesURL.URLByAppendingPathComponent(kVideoMakerMusicCacheDirectory).URLByAppendingPathComponent(musicDataFilenameFromTrackId(trackId))
        return musicDataURL
    }
    
    private static func musicDataFilenameFromTrackId(trackId: Int) -> String {
        return "\(trackId)" + ".m4a"
    }
    
    private static func trackInfoFilenameFromTrackId(trackId: Int) -> String {
        return "\(trackId)" + "TrackInfo.dat"
    }
    
    private static func trackInfoURLfromMusicDataURL(musicDataURL: NSURL) -> NSURL {
        let trackInfoFilename = trackInfoFilenameFromTrackId(Int(musicDataURL.URLByDeletingPathExtension!.lastPathComponent!)!)
        let trackInfoURL = musicDataURL.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(trackInfoFilename)
        return trackInfoURL
    }
}